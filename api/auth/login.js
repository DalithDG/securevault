const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { getDb, setCors } = require('../_lib/mongo');

module.exports = async (req, res) => {
  setCors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ ok: false, error: 'Method not allowed' });

  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const email = String(body.email || '').trim().toLowerCase();
    const password = String(body.password || '');

    if (!email || !password) {
      return res.status(400).json({ ok: false, error: 'Ingresa correo y contraseña.' });
    }

    const db = await getDb();
    const user = await db.collection('users').findOne({ email });
    if (!user) {
      return res.status(401).json({ ok: false, error: 'Cuenta no registrada. Crea una cuenta primero.' });
    }

    const valid = bcrypt.compareSync(password, user.passwordHash || '');
    if (!valid) {
      return res.status(401).json({ ok: false, error: 'Contraseña incorrecta.' });
    }

    return res.status(200).json({
      ok: true,
      email,
      token: crypto.randomUUID(),
    });
  } catch (err) {
    return res.status(500).json({ ok: false, error: err.message });
  }
};
