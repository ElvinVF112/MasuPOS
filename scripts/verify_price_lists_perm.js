const sql = require("mssql");
const fs = require("fs");
const path = require("path");

function loadEnv(fileName) {
  const filePath = path.resolve(process.cwd(), fileName);
  if (!fs.existsSync(filePath)) return;
  fs.readFileSync(filePath, "utf8").split(/\r?\n/).forEach((line) => {
    const t = line.trim();
    if (!t || t.startsWith("#")) return;
    const eq = t.indexOf("=");
    if (eq <= 0) return;
    const key = t.slice(0, eq).trim();
    let val = t.slice(eq + 1).trim();
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) val = val.slice(1, -1);
    if (!(key in process.env)) process.env[key] = val;
  });
}

async function run() {
  loadEnv(".env.local");
  const pool = await new sql.ConnectionPool(process.env.DATABASE_URL).connect();
  try {
    const r = await pool.request().query(`
      SELECT p.Nombre AS Permiso, pa.Ruta, pa.IdModulo, rp.IdRol, r.Nombre AS Rol
      FROM dbo.Permisos p
      JOIN dbo.Pantallas pa ON p.IdPantalla = pa.IdPantalla
      JOIN dbo.RolesPermisos rp ON p.IdPermiso = rp.IdPermiso
      JOIN dbo.Roles r ON rp.IdRol = r.IdRol
      WHERE pa.Ruta = '/config/catalog/price-lists'
        AND p.RowStatus = 1
        AND rp.RowStatus = 1
    `);
    console.log("Permisos para /config/catalog/price-lists:");
    r.recordset.forEach((row) => console.log(" ", row));
  } finally {
    await pool.close();
  }
}

run().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
