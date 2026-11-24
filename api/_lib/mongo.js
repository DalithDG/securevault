const { MongoClient } = require('mongodb');

const DEFAULT_URI =
  'mongodb+srv://dalithg29_db_user:JFuMsjeqZW2L9w2G@secucode.ufcu1h0.mongodb.net/securevault?retryWrites=true&w=majority';

const uri = process.env.MONGODB_URI || DEFAULT_URI;

let clientPromise;
if (!global._mongoClientPromise) {
  const client = new MongoClient(uri);
  global._mongoClientPromise = client.connect();
}
clientPromise = global._mongoClientPromise;

async function getDb() {
  const client = await clientPromise;
  return client.db('securevault');
}

function setCors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

module.exports = { getDb, setCors };
