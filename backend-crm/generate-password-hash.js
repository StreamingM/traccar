const bcrypt = require('bcryptjs');

// Password que queremos hashear
const password = 'admin123';

// Generar hash (10 rondas de salt)
bcrypt.hash(password, 10, (err, hash) => {
  if (err) {
    console.error('Error generando hash:', err);
    process.exit(1);
  }

  console.log('Password:', password);
  console.log('Hash bcrypt:', hash);
  console.log('\nUsa este hash en el seed SQL:');
  console.log(`'${hash}'`);
});
