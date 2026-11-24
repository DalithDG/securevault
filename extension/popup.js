const DEFAULT_SERVER_URL = 'https://securevault-276j.onrender.com';

const serverUrlInput = document.getElementById('serverUrlInput');
const userIdInput = document.getElementById('userIdInput');
const searchInput = document.getElementById('searchInput');
const syncBtn = document.getElementById('syncBtn');
const toggleFormBtn = document.getElementById('toggleFormBtn');
const saveForm = document.getElementById('saveForm');
const ccInput = document.getElementById('ccInput');
const nombreInput = document.getElementById('nombreInput');
const siteInput = document.getElementById('siteInput');
const urlInput = document.getElementById('urlInput');
const usernameInput = document.getElementById('usernameInput');
const passwordInput = document.getElementById('passwordInput');
const saveBtn = document.getElementById('saveBtn');
const statusEl = document.getElementById('status');
const listEl = document.getElementById('list');

let cachedClients = [];

function getBaseUrl() {
  return (serverUrlInput.value || DEFAULT_SERVER_URL).trim().replace(/\/+$/, '');
}

function getUserId() {
  return (userIdInput.value || 'default').trim();
}

async function init() {
  const data = await chrome.storage.local.get([
    'serverUrl',
    'userId',
    'clients',
    'pendingCredential',
  ]);
  serverUrlInput.value = data.serverUrl || DEFAULT_SERVER_URL;
  userIdInput.value = data.userId || 'default';
  cachedClients = Array.isArray(data.clients) ? data.clients : [];

  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (tab?.url) {
    urlInput.value = tab.url;
    try {
      siteInput.value = new URL(tab.url).hostname;
    } catch (_) { }
  }
  if (data.pendingCredential) {
    if (data.pendingCredential.url) urlInput.value = data.pendingCredential.url;
    if (data.pendingCredential.username) usernameInput.value = data.pendingCredential.username;
    if (data.pendingCredential.password) passwordInput.value = data.pendingCredential.password;
  }

  render();
  await syncFromServer();
}

async function syncFromServer() {
  const baseUrl = getBaseUrl();
  const userId = getUserId();
  await chrome.storage.local.set({ serverUrl: baseUrl, userId });
  statusEl.textContent = `Conectando con ${baseUrl}...`;

  try {
    const res = await fetch(`${baseUrl}/api/vault/${encodeURIComponent(userId)}`);
    if (!res.ok) {
      statusEl.textContent = `Error del servidor (${res.status})`;
      return;
    }
    const payload = await res.json();
    cachedClients = Array.isArray(payload.clients) ? payload.clients : [];
    await chrome.storage.local.set({
      clients: cachedClients,
      lastSync: new Date().toISOString(),
    });
    statusEl.textContent = `Conectado • ${cachedClients.length} ${cachedClients.length === 1 ? 'cliente' : 'clientes'}`;
    render();
  } catch (err) {
    statusEl.textContent = `No se pudo conectar con ${baseUrl}`;
  }
}

async function saveToServer() {
  const baseUrl = getBaseUrl();
  const userId = getUserId();
  await chrome.storage.local.set({ serverUrl: baseUrl, userId });

  const payload = {
    cc: ccInput.value.trim(),
    nombre: nombreInput.value.trim(),
    siteName: siteInput.value.trim(),
    url: urlInput.value.trim(),
    username: usernameInput.value.trim(),
    password: passwordInput.value,
  };

  if (!payload.url || !payload.username || !payload.password) {
    statusEl.textContent = 'Completa URL, Usuario y Password para guardar.';
    return;
  }
  if (!payload.cc && !payload.nombre) {
    statusEl.textContent = 'Ingresa CC o Nombre del cliente.';
    return;
  }

  statusEl.textContent = 'Guardando en SecureVault...';
  try {
    const res = await fetch(
      `${baseUrl}/api/vault/${encodeURIComponent(userId)}/extension/save`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      },
    );
    const data = await res.json();
    if (!res.ok || !data.ok) {
      statusEl.textContent = data.error || 'No se pudo guardar.';
      return;
    }
    cachedClients = Array.isArray(data.clients) ? data.clients : cachedClients;
    await chrome.storage.local.set({ clients: cachedClients });
    await chrome.storage.local.remove('pendingCredential');
    saveForm.classList.remove('open');
    statusEl.textContent = `Guardado en ${data.client?.nombre || 'cliente'}`;
    render();
  } catch (err) {
    statusEl.textContent = `No se pudo conectar con ${baseUrl}`;
  }
}

function render() {
  const q = (searchInput.value || '').trim().toLowerCase();
  listEl.innerHTML = '';

  const entries = [];
  for (const client of cachedClients) {
    const pages = Array.isArray(client.pages) ? client.pages : [];
    for (const page of pages) {
      const hay = `${client.nombre || ''} ${client.cc || ''} ${page.siteName || ''} ${page.url || ''} ${page.username || ''}`.toLowerCase();
      if (!q || hay.includes(q)) {
        entries.push({ client, page });
      }
    }
  }

  if (entries.length === 0) {
    listEl.innerHTML = '<div class="status">No hay páginas sincronizadas. Usa "+ Guardar" o agrega páginas en la app.</div>';
    return;
  }

  for (const { client, page } of entries) {
    const card = document.createElement('div');
    card.className = 'card';
    card.innerHTML = `
      <div class="client">${escapeHtml(client.nombre || '')} • CC: ${escapeHtml(client.cc || '')}</div>
      <div class="site">${escapeHtml(page.siteName || page.url || 'Página')}</div>
      <div class="meta">URL: ${escapeHtml(page.url || '')}</div>
      <div class="meta">Usuario: ${escapeHtml(page.username || '')}</div>
      <div class="actions">
        <button class="fill-btn">Autocompletar</button>
        <button class="copy-btn secondary">Copiar clave</button>
      </div>
    `;
    card.querySelector('.fill-btn').addEventListener('click', async () => {
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      if (tab?.id) {
        chrome.tabs.sendMessage(tab.id, {
          type: 'FILL_CREDENTIALS',
          payload: {
            username: page.username || '',
            password: page.password || '',
          },
        });
      }
    });
    card.querySelector('.copy-btn').addEventListener('click', async () => {
      await navigator.clipboard.writeText(page.password || '');
      statusEl.textContent = 'Contraseña copiada';
    });
    listEl.appendChild(card);
  }
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

toggleFormBtn.addEventListener('click', () => {
  saveForm.classList.toggle('open');
});
syncBtn.addEventListener('click', syncFromServer);
saveBtn.addEventListener('click', saveToServer);
searchInput.addEventListener('input', render);
init();
