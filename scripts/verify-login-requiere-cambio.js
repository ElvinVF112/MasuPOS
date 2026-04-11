const fs = require("fs")
const path = require("path")
const sql = require("mssql")

function loadEnv(fileName) {
  const filePath = path.resolve(process.cwd(), fileName)
  if (!fs.existsSync(filePath)) return
  for (const line of fs.readFileSync(filePath, "utf8").split(/\r?\n/)) {
    const trimmed = line.trim()
    if (!trimmed || trimmed.startsWith("#")) continue
    const idx = trimmed.indexOf("=")
    if (idx < 1) continue
    const key = trimmed.slice(0, idx).trim()
    let value = trimmed.slice(idx + 1).trim()
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1)
    }
    if (!(key in process.env)) process.env[key] = value
  }
}

async function run() {
  loadEnv(".env.local")
  loadEnv(".env")
  const cs = process.env.DATABASE_URL
  if (!cs) throw new Error("DATABASE_URL missing")

  const pool = await new sql.ConnectionPool(cs).connect()
  try {
    const username = `qa_login_req_${Date.now()}`
    const plain = "qa123"

    const create = await pool
      .request()
      .input("Accion", "I")
      .input("IdRol", 1)
      .input("Nombres", "QA")
      .input("Apellidos", "LoginReq")
      .input("NombreUsuario", username)
      .input("Correo", `${username}@masu.local`)
      .input("ClaveHash", plain)
      .input("RequiereCambioClave", true)
      .input("Bloqueado", false)
      .input("Activo", true)
      .input("UsuarioCreacion", 1)
      .execute("dbo.spUsuariosCRUD")

    const id = create.recordset?.[0]?.IdUsuario
    const login = await pool
      .request()
      .input("NombreUsuario", username)
      .input("ClaveHash", plain)
      .input("Canal", "WEB")
      .input("IpAddress", "127.0.0.1")
      .input("UserAgent", "qa-script")
      .execute("dbo.spAuthLogin")

    const row = login.recordset?.[0]
    console.log("LOGIN_CHECK", {
      IdUsuario: row?.IdUsuario,
      NombreUsuario: row?.NombreUsuario,
      RequiereCambioClave: row?.RequiereCambioClave,
    })

    await pool.request().input("Accion", "D").input("IdUsuario", id).input("UsuarioModificacion", 1).execute("dbo.spUsuariosCRUD")
  } finally {
    await pool.close()
  }
}

run().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error))
  process.exit(1)
})
