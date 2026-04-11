const sql = require("mssql");

const connectionString = process.env.DATABASE_URL || "Server=localhost;Database=DbMasuPOS;User Id=Masu;Password=M@$uM@$t3rP@s$;TrustServerCertificate=True";

async function main() {
  try {
    const pool = await sql.connect(connectionString);
    console.log("Connected to DB");

    // Check if category 0 exists
    const check = await pool.request().query("SELECT * FROM dbo.Categorias WHERE IdCategoria = 0");
    if (check.recordset.length > 0) {
      console.log("Category 0 already exists:", check.recordset[0]);
    } else {
      // Insert with proper values - Activo must be 1
      await pool.request().query(`
        SET IDENTITY_INSERT dbo.Categorias ON;
        INSERT INTO dbo.Categorias (IdCategoria, Nombre, Descripcion, Activo, RowStatus, IdCategoriaPadre, Codigo, MostrarEnPOS, Imagen)
        VALUES (0, 'Sin Categoría', 'Productos sin categoría asignada', 1, 1, NULL, 'SIN-CAT', 0, NULL);
        SET IDENTITY_INSERT dbo.Categorias OFF;
      `);
      console.log("Category 0 created successfully!");
    }

    // Verify
    const verify = await pool.request().query("SELECT * FROM dbo.Categorias WHERE IdCategoria = 0");
    console.log("Category 0:", verify.recordset[0]);

    await sql.close();
    console.log("Done");
  } catch (err) {
    console.error("Error:", err.message);
  }
}

main();