const { setCors } = require('./_lib/mongo');

module.exports = async (req, res) => {
  setCors(res);
  if (req.method === 'OPTIONS') return res.status(200).end();
  return res.status(200).json({ ok: true, service: 'securevault-vercel-api' });
};
