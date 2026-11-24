const { getDb, setCors } = require('../../_lib/mongo');

module.exports = async (req, res) => {
  setCors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();

  const userId = decodeURIComponent(String(req.query.userId || 'default')).trim().toLowerCase();

  try {
    const db = await getDb();
    const vaults = db.collection('vaults');

    if (req.method === 'GET') {
      const doc = await vaults.findOne({ userId });
      const blob = doc?.encryptedBlob || JSON.stringify({ version: 1, clients: [] });
      res.setHeader('Content-Type', 'application/json');
      return res.status(200).send(blob);
    }

    if (req.method === 'POST') {
      const blob = typeof req.body === 'string' ? req.body : JSON.stringify(req.body || { version: 1, clients: [] });
      await vaults.updateOne(
        { userId },
        { $set: { userId, encryptedBlob: blob } },
        { upsert: true },
      );
      return res.status(200).json({ ok: true });
    }

    return res.status(405).json({ ok: false, error: 'Method not allowed' });
  } catch (err) {
    return res.status(500).json({ ok: false, error: err.message });
  }
};
