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

    if (!email || !email.includes('@')) {
      return res.status(400).json({ ok: false, error: 'Ingresa un correo electrónico válido.' });
    }
    if (password.length < 6) {
      return res.status(400).json({ ok: false, error: 'La contraseña debe tener al menos 6 caracteres.' });
    }

    const db = await getDb();
    const users = db.collection('users');
    const vaults = db.collection('vaults');

    const existing = await users.findOne({ email });
    if (existing) {
      return res.status(409).json({ ok: false, error: 'Este correo ya está registrado.' });
    }

    const passwordHash = bcrypt.hashSync(password, 10);
    await users.insertOne({
      email,
      passwordHash,
      createdAt: new Date().toISOString(),
    });

    const existingVault = await vaults.findOne({ userId: email });
    if (!existingVault) {
      await vaults.insertOne({
        userId: email,
        encryptedBlob: JSON.stringify({ version: 1, clients: [] }),
      });
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
