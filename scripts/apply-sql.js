const fs = require('fs');
const sql = require('mssql');
const path = require('path');

const config = {
  server: 'localhost',
  database: 'DbMasuPOS',
  user: 'Masu',
  password: 'M@$uM@$t3rP@s$',
  options: { trustServerCertificate: true }
};

const scriptPath = process.argv[2];
if (!scriptPath) {
  console.error('Usage: node apply-sql.js <path-to-sql-file>');
  process.exit(1);
}

const script = fs.readFileSync(scriptPath, 'utf8');
const batches = script.split(/^GO$/im).filter(b => b.trim());

(async () => {
  const pool = await sql.connect(config);
  for (const batch of batches) {
    const trimmed = batch.trim();
    if (!trimmed) continue;
    try {
      await pool.request().query(trimmed);
      console.log('OK:', trimmed.slice(0, 80).replace(/\s+/g, ' '));
    } catch (err) {
      console.error('ERROR:', err.message);
      console.error('SQL:', trimmed.slice(0, 200));
    }
  }
  await pool.close();
  console.log('\nDone.');
})().catch(e => { console.error(e); process.exit(1); });
