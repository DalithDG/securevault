const DEFAULT_SERVER_URL = 'https://securevault-dgteams.vercel.app';

const serverUrlInput = document.getElementById('serverUrlInput');
const userIdInput = document.getElementById('userIdInput');
const lookupBtn = document.getElementById('lookupBtn');
const clearBtn = document.getElementById('clearBtn');
const ccInput = document.getElementById('ccInput');
const nombreInput = document.getElementById('nombreInput');
const siteInput = document.getElementById('siteInput');
const urlInput = document.getElementById('urlInput');
const usernameInput = document.getElementById('usernameInput');
const passwordInput = document.getElementById('passwordInput');
const saveBtn = document.getElementById('saveBtn');
const statusEl = document.getElementById('status');
const listEl = document.getElementById('list');

let currentHost = '';

function getBaseUrl() {
  return (serverUrlInput.value || DEFAULT_SERVER_URL).trim().replace(/\/+$/, '');
}

function getUserId() {
  return (userIdInput.value || '').trim().toLowerCase();
}

async function init() {
  await chrome.storage.local.remove(['clients', 'lastSync']);
  const data = await chrome.storage.local.get(['serverUrl', 'userId', 'pendingCredential']);
  serverUrlInput.value = data.serverUrl || DEFAULT_SERVER_URL;
  userIdInput.value = data.userId || '';

  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (tab?.url) {
    urlInput.value = tab.url;
    try {
      currentHost = new URL(tab.url).hostname.replace(/^www\./, '').toLowerCase();
      siteInput.value = currentHost;
    } catch (_) {}
  }

  if (data.pendingCredential) {
    if (data.pendingCredential.url) urlInput.value = data.pendingCredential.url;
    if (data.pendingCredential.username) usernameInput.value = data.pendingCredential.username;
    if (data.pendingCredential.password) passwordInput.value = data.pendingCredential.password;
    statusEl.textContent = 'Credenciales capturadas listas para enviar a la app.';
  }
}

async function clearAllFields() {
  ccInput.value = '';
  nombreInput.value = '';
  usernameInput.value = '';
  passwordInput.value = '';
  listEl.innerHTML = '';
  await chrome.storage.local.remove(['clients', 'pendingCredential', 'lastSync']);
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (tab?.id) {
    chrome.action.setBadgeText({ text: '', tabId: tab.id });
  }
}

async function saveToAppAndClear() {
  const baseUrl = getBaseUrl();
  const userId = getUserId();
  if (!userId) {
    statusEl.textContent = 'Ingresa el correo de tu cuenta para enviarlo a la app.';
    return;
  }
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
    statusEl.textContent = 'Completa URL, Usuario y Password para enviar.';
    return;
  }
  if (!payload.cc && !payload.nombre) {
    statusEl.textContent = 'Ingresa CC o Nombre del cliente.';
    return;
  }

  statusEl.textContent = 'Enviando datos a la app...';
  try {
    const res = await fetch(
      `${baseUrl}/api/vault/${encodeURIComponent(userId)}/extension/save`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      },
    );
    const raw = await res.text();
    let data = {};
    try { data = JSON.parse(raw); } catch (_) {}
    if (!res.ok || !data.ok) {
      statusEl.textContent = data.error || `Error del servidor (${res.status})`;
      return;
    }

    await clearAllFields();
    statusEl.textContent = `Enviado a la app (${data.client?.nombre || 'cliente'}) y limpiado de la extensión.`;
  } catch (err) {
    statusEl.textContent = `No se pudo conectar con ${baseUrl}`;
  }
}

async function lookupCurrentSite() {
  const baseUrl = getBaseUrl();
  const userId = getUserId();
  if (!userId) {
    statusEl.textContent = 'Ingresa el correo de tu cuenta primero.';
    return;
  }
  await chrome.storage.local.set({ serverUrl: baseUrl, userId });
  listEl.innerHTML = '';
  statusEl.textContent = `Buscando credenciales para ${currentHost || 'este sitio'}...`;

  try {
    const res = await fetch(`${baseUrl}/api/vault/${encodeURIComponent(userId)}`);
    if (!res.ok) {
      statusEl.textContent = `Error del servidor (${res.status})`;
      return;
    }
    const payload = await res.json();
    const clients = Array.isArray(payload.clients) ? payload.clients : [];

    const matches = [];
    for (const client of clients) {
      const pages = Array.isArray(client.pages) ? client.pages : [];
      for (const page of pages) {
        if (currentHost && (page.url || '').toLowerCase().includes(currentHost)) {
          matches.push({ client, page });
        }
      }
    }

    if (matches.length === 0) {
      statusEl.textContent = 'No hay credenciales guardadas para este sitio.';
      return;
    }

    statusEl.textContent = `${matches.length} coincidencia(s) para ${currentHost}.`;
    for (const { client, page } of matches) {
      const card = document.createElement('div');
      card.className = 'card';
      card.innerHTML = `
        <div class="client">${escapeHtml(client.nombre || '')} • CC: ${escapeHtml(client.cc || '')}</div>
        <div class="site">${escapeHtml(page.siteName || page.url || 'Página')}</div>
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
        listEl.innerHTML = '';
        statusEl.textContent = 'Autocompletado y vista limpiada.';
      });
      card.querySelector('.copy-btn').addEventListener('click', async () => {
        await navigator.clipboard.writeText(page.password || '');
        listEl.innerHTML = '';
        statusEl.textContent = 'Contraseña copiada y vista limpiada.';
      });
      listEl.appendChild(card);
    }
  } catch (err) {
    statusEl.textContent = `No se pudo conectar con ${baseUrl}`;
  }
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

saveBtn.addEventListener('click', saveToAppAndClear);
lookupBtn.addEventListener('click', lookupCurrentSite);
clearBtn.addEventListener('click', async () => {
  await clearAllFields();
  statusEl.textContent = 'Datos eliminados de la extensión.';
});
init();
