const fs = require("fs")
const path = require("path")
const sql = require("mssql")

function loadEnv(fileName) {
  const filePath = path.resolve(process.cwd(), fileName)
  if (!fs.existsSync(filePath)) return
  for (const line of fs.readFileSync(filePath, "utf8").split(/\r?\n/)) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith("#")) continue
    const index = trimmed.indexOf("=")
    if (index < 1) continue
    const key = trimmed.slice(0, index).trim()
    let value = trimmed.slice(index + 1).trim()
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1)
    }
    if (!(key in process.env)) process.env[key] = value
  }
}

async function run() {
  loadEnv(".env.local")
  loadEnv(".env")

  const connectionString = process.env.DATABASE_URL
  if (!connectionString) throw new Error("DATABASE_URL missing")

  const pool = await new sql.ConnectionPool(connectionString).connect()
  try {
    const username = `qa_reqcambio_${Date.now()}`

    const createResult = await pool
      .request()
      .input("Accion", "I")
      .input("IdRol", 1)
      .input("Nombres", "QA")
      .input("Apellidos", "Requiere")
      .input("NombreUsuario", username)
      .input("Correo", `${username}@masu.local`)
      .input("ClaveHash", "qa123")
      .input("RequiereCambioClave", true)
      .input("Bloqueado", false)
      .input("Activo", true)
      .input("UsuarioCreacion", 1)
      .execute("dbo.spUsuariosCRUD")

    const idUsuario = createResult.recordset?.[0]?.IdUsuario
    if (!idUsuario) throw new Error("No se pudo obtener IdUsuario creado")

    const createdCheck = await pool
      .request()
      .input("IdUsuario", idUsuario)
      .query("SELECT IdUsuario, NombreUsuario, RequiereCambioClave, Bloqueado, Activo FROM dbo.Usuarios WHERE IdUsuario = @IdUsuario")

    await pool
      .request()
      .input("Accion", "A")
      .input("IdUsuario", idUsuario)
      .input("IdRol", 1)
      .input("Nombres", "QA")
      .input("Apellidos", "Requiere")
      .input("NombreUsuario", username)
      .input("Correo", `${username}@masu.local`)
      .input("RequiereCambioClave", false)
      .input("Bloqueado", false)
      .input("Activo", true)
      .input("UsuarioModificacion", 1)
      .execute("dbo.spUsuariosCRUD")

    const updatedCheck = await pool
      .request()
      .input("IdUsuario", idUsuario)
      .query("SELECT IdUsuario, NombreUsuario, RequiereCambioClave, Bloqueado, Activo FROM dbo.Usuarios WHERE IdUsuario = @IdUsuario")

    await pool
      .request()
      .input("Accion", "D")
      .input("IdUsuario", idUsuario)
      .input("UsuarioModificacion", 1)
      .execute("dbo.spUsuariosCRUD")

    console.log("CREATE_CHECK", createdCheck.recordset?.[0])
    console.log("UPDATE_CHECK", updatedCheck.recordset?.[0])
  } finally {
    await pool.close()
  }
}

run().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error))
  process.exit(1)
})
