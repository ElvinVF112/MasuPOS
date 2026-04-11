const sql = require('mssql');

const config = {
  server: 'localhost',
  database: 'DbMasuPOS',
  user: 'Masu',
  password: 'M@$uM@$t3rP@s$',
  options: { trustServerCertificate: true }
};

async function main() {
  const pool = await sql.connect(config);
  
  // Agregar parámetro @Eslogan al SP
  await pool.request().query(`
    ALTER PROCEDURE dbo.spEmpresaCRUD
    AS
    BEGIN
        DECLARE @Eslogan NVARCHAR(500);
    END
  `);
  console.log('SP actualizado');
  
  // Verificar
  const spCheck = await pool.request().query(`
    SELECT PARAMETER_NAME FROM INFORMATION_SCHEMA.PARAMETERS 
    WHERE SPECIFIC_NAME = 'spEmpresaCRUD' AND PARAMETER_NAME = '@Eslogan'
  `);
  console.log('Ahora @Eslogan existe:', spCheck.recordset.length > 0);
  
  sql.close();
}

main().catch(e => console.error('Error:', e.message));