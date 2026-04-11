const fs = require("fs")
const path = require("path")
const sql = require("mssql")

function loadEnvFile(fileName) {
  const filePath = path.resolve(process.cwd(), fileName)
  if (!fs.existsSync(filePath)) return
  const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/)
  for (const line of lines) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith("#")) continue
    const eq = trimmed.indexOf("=")
    if (eq <= 0) continue
    const key = trimmed.slice(0, eq).trim()
    let value = trimmed.slice(eq + 1).trim()
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) value = value.slice(1, -1)
    if (!(key in process.env)) process.env[key] = value
  }
}

function normalizeToAlterProcedure(definition) {
  let output = definition
  output = output.replace(/create\s+or\s+alter\s+proc(?:edure)?/i, "ALTER PROCEDURE")
  output = output.replace(/create\s+proc(?:edure)?/i, "ALTER PROCEDURE")
  return output
}

function injectSessionParams(definition) {
  const hasIdSesion = /@IdSesion\b/i.test(definition)
  const hasTokenSesion = /@TokenSesion\b/i.test(definition)
  if (hasIdSesion && hasTokenSesion) return { changed: false, sqlText: definition }

  const asMatch = /\r?\nAS\b/i.exec(definition)
  if (!asMatch || asMatch.index < 0) {
    throw new Error("No se pudo ubicar el bloque AS del procedimiento.")
  }

  const extra = []
  if (!hasIdSesion) extra.push("  @IdSesion INT = NULL")
  if (!hasTokenSesion) extra.push("  @TokenSesion NVARCHAR(128) = NULL")

  const beforeAs = definition.slice(0, asMatch.index)
  const afterAs = definition.slice(asMatch.index)
  const injection = `,\n${extra.join(",\n")}\n`
  return { changed: true, sqlText: `${beforeAs}${injection}${afterAs}` }
}

async function run() {
  loadEnvFile(".env.local")
  loadEnvFile(".env")
  const connectionString = process.env.DATABASE_URL
  if (!connectionString) throw new Error("DATABASE_URL no esta definido.")

  const targets = [
    "spRolesCRUD",
    "spPermisosCRUD",
    "spMesasCRUD",
    "spCategoriasCRUD",
    "spAreasCRUD",
    "spRecursosCRUD",
    "spTiposRecursoCRUD",
    "spCategoriasRecursoCRUD",
    "spRolesPermisosCRUD",
  ]

  const pool = await new sql.ConnectionPool(connectionString).connect()
  const generated = []
  try {
    for (const procName of targets) {
      const defResult = await pool.request().input("procName", procName).query(`
        SELECT OBJECT_DEFINITION(OBJECT_ID(CONCAT('dbo.', @procName))) AS DefinitionText;
      `)

      const definition = defResult.recordset?.[0]?.DefinitionText
      if (!definition) {
        console.log(`${procName}: no existe, omitido`)
        continue
      }

      const altered = normalizeToAlterProcedure(definition)
      const { changed, sqlText } = injectSessionParams(altered)
      if (!changed) {
        console.log(`${procName}: ya contiene parametros de sesion`)
        continue
      }

      await pool.request().batch(sqlText)
      generated.push(`-- ${procName}\n${sqlText}\nGO\n`)
      console.log(`${procName}: actualizado`)
    }
  } finally {
    await pool.close()
  }

  if (generated.length > 0) {
    const outputPath = path.resolve(process.cwd(), "database", "11_sp_crud_sesion_context.generated.sql")
    fs.writeFileSync(outputPath, generated.join("\n"), "utf8")
    console.log(`Script consolidado generado: ${outputPath}`)
  }
}

run().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error))
  process.exit(1)
})
