const sql = require('mssql');
const fs = require('fs');

const config = {
  server: 'localhost',
  database: 'DbMasuPOS',
  user: 'Masu',
  password: 'M@$uM@$t3rP@s$',
  options: { trustServerCertificate: true }
};

async function main() {
  const pool = await sql.connect(config);
  
  // 1. Verificar que existe la columna
  const colCheck = await pool.request().query(`
    SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'Empresa' AND COLUMN_NAME = 'Eslogan'
  `);
  console.log('Columna Eslogan:', colCheck.recordset.length > 0 ? 'EXISTE' : 'NO EXISTE');
  
  // 2. Ver dato actual
  const data = await pool.request().query(`SELECT Eslogan FROM dbo.Empresa WHERE RowStatus = 1`);
  console.log('Eslogan actual:', data.recordset[0]?.Eslogan);
  
  // 3. Ver parámetros del SP
  const spCheck = await pool.request().query(`
    SELECT PARAMETER_NAME FROM INFORMATION_SCHEMA.PARAMETERS 
    WHERE SPECIFIC_NAME = 'spEmpresaCRUD' AND PARAMETER_NAME = '@Eslogan'
  `);
  console.log('Parámetro @Eslogan en SP:', spCheck.recordset.length > 0 ? 'EXISTE' : 'NO EXISTE');
  
  sql.close();
}

main().catch(console.error);