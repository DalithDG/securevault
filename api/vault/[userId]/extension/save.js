const crypto = require('crypto');
const { getDb, setCors } = require('../../../_lib/mongo');

module.exports = async (req, res) => {
  setCors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ ok: false, error: 'Method not allowed' });

  const userId = decodeURIComponent(String(req.query.userId || 'default')).trim().toLowerCase();

  try {
    const payload = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const cc = String(payload.cc || '').trim();
    const nombre = String(payload.nombre || '').trim();
    const url = String(payload.url || '').trim();
    const username = String(payload.username || '').trim();
    const password = String(payload.password || '');
    const siteName = String(payload.siteName || '').trim();

    if (!url || !username || !password) {
      return res.status(400).json({ ok: false, error: 'URL, usuario y password requeridos' });
    }

    const db = await getDb();
    const vaults = db.collection('vaults');
    const doc = await vaults.findOne({ userId });

    let root = { version: 1, clients: [] };
    if (doc?.encryptedBlob) {
      try {
        root = JSON.parse(doc.encryptedBlob);
      } catch (_) {}
    }
    const clients = Array.isArray(root.clients) ? root.clients : [];
    const now = new Date().toISOString();

    const newPage = {
      id: crypto.randomUUID(),
      siteName,
      url,
      username,
      password,
      notes: '',
      updatedAt: now,
    };

    let target = clients.find((c) => {
      const cCc = String(c.cc || '').trim();
      const cNombre = String(c.nombre || '').trim();
      return (cc && cCc.toLowerCase() === cc.toLowerCase()) ||
        (!cc && nombre && cNombre.toLowerCase() === nombre.toLowerCase());
    });

    if (!target) {
      target = {
        id: crypto.randomUUID(),
        cc: cc || 'S/N',
        nombre: nombre || 'Cliente sin nombre',
        pages: [newPage],
        createdAt: now,
        updatedAt: now,
      };
      clients.unshift(target);
    } else {
      target.pages = Array.isArray(target.pages) ? target.pages : [];
      target.pages.unshift(newPage);
      target.updatedAt = now;
    }

    root.version = 1;
    root.updatedAt = now;
    root.clients = clients;

    await vaults.updateOne(
      { userId },
      { $set: { userId, encryptedBlob: JSON.stringify(root) } },
      { upsert: true },
    );

    return res.status(200).json({ ok: true, client: target, clients });
  } catch (err) {
    return res.status(500).json({ ok: false, error: err.message });
  }
};
