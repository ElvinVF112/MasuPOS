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
  
  // Obtener definición actual del SP
  const result = await pool.request().query(`
    SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.spEmpresaCRUD')) AS sp_def
  `);
  
  let spDef = result.recordset[0].sp_def;
  
  // Agregar parámetro @Eslogan después de @SistemaMedida
  if (!spDef.includes('@Eslogan')) {
    spDef = spDef.replace(
      /@SistemaMedida\s+NVARCHAR\(20\)\s*=?\s*NULL/,
      '@SistemaMedida NVARCHAR(20) = NULL,\n    @Eslogan NVARCHAR(500) = NULL'
    );
    
    // Agregar Eslogan en los SELECTs
    if (!spDef.includes('E.Eslogan')) {
      // Agregar en SELECT de acción L
      spDef = spDef.replace(
        /E\.SistemaMedida\s*,\s*$/m,
        'E.SistemaMedida,\n            E.Eslogan'
      );
    }
    
    console.log('Nueva definición preparada');
    console.log('Contiene @Eslogan:', spDef.includes('@Eslogan'));
    console.log('Contiene E.Eslogan:', spDef.includes('E.Eslogan'));
  }
  
  sql.close();
  console.log('\nEl SP necesita ser actualizado manualmente o reemplazar completamente');
  console.log('El problema es que el SP existente no tiene el parámetro @Eslogan');
}

main().catch(e => console.error('Error:', e.message));