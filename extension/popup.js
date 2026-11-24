const DEFAULT_SERVER_URL = 'https://securevault-dgteams.vercel.app';

const serverUrlInput = document.getElementById('serverUrlInput');
const userIdInput = document.getElementById('userIdInput');
const settingsBtn = document.getElementById('settingsBtn');
const settingsDrawer = document.getElementById('settingsDrawer');
const lookupBtn = document.getElementById('lookupBtn');
const clearBtn = document.getElementById('clearBtn');
const ccInput = document.getElementById('ccInput');
const nombreInput = document.getElementById('nombreInput');
const siteInput = document.getElementById('siteInput');
const urlInput = document.getElementById('urlInput');
const usernameInput = document.getElementById('usernameInput');
const passwordInput = document.getElementById('passwordInput');
const togglePassBtn = document.getElementById('togglePassBtn');
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

function setStatus(text, type = '') {
  statusEl.textContent = text;
  statusEl.className = `status-pill ${type}`.trim();
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
    setStatus('Credenciales capturadas listas para enviar.', 'ok');
  }
}

async function clearAllFields() {
  ccInput.value = '';
  nombreInput.value = '';
  usernameInput.value = '';
  passwordInput.value = '';
  passwordInput.type = 'password';
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
    setStatus('Ingresa el correo de tu cuenta para enviarlo.', 'err');
    userIdInput.focus();
    return;
  }
  await chrome.storage.local.set({ serverUrl: baseUrl, userId });

  const payload = {
    userId,
    cc: ccInput.value.trim(),
    nombre: nombreInput.value.trim(),
    siteName: siteInput.value.trim(),
    url: urlInput.value.trim(),
    username: usernameInput.value.trim(),
    password: passwordInput.value,
  };

  if (!payload.url || !payload.username || !payload.password) {
    setStatus('Completa URL, Usuario y Password.', 'err');
    return;
  }
  if (!payload.cc && !payload.nombre) {
    setStatus('Ingresa CC o Nombre del cliente.', 'err');
    return;
  }

  setStatus('Enviando datos a la app...');
  saveBtn.disabled = true;
  try {
    const vaultUrl = `${baseUrl}/api/vault/${encodeURIComponent(userId)}`;
    const getRes = await fetch(vaultUrl);
    if (!getRes.ok) {
      setStatus(`Error del servidor (${getRes.status})`, 'err');
      return;
    }

    let root = { version: 1, clients: [] };
    try {
      const parsed = await getRes.json();
      if (parsed && Array.isArray(parsed.clients)) root = parsed;
    } catch (_) {}

    const clients = root.clients;
    const now = new Date().toISOString();
    const newPage = {
      id: crypto.randomUUID(),
      siteName: payload.siteName,
      url: payload.url,
      username: payload.username,
      password: payload.password,
      notes: '',
      updatedAt: now,
    };

    let target = clients.find((c) => {
      const cCc = String(c.cc || '').trim();
      const cNombre = String(c.nombre || '').trim();
      return (payload.cc && cCc.toLowerCase() === payload.cc.toLowerCase()) ||
        (!payload.cc && payload.nombre && cNombre.toLowerCase() === payload.nombre.toLowerCase());
    });

    if (!target) {
      target = {
        id: crypto.randomUUID(),
        cc: payload.cc || 'S/N',
        nombre: payload.nombre || 'Cliente sin nombre',
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

    const postRes = await fetch(vaultUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'text/plain' },
      body: JSON.stringify(root),
    });
    if (!postRes.ok) {
      setStatus(`Error del servidor (${postRes.status})`, 'err');
      return;
    }

    const savedName = target.nombre || 'la app';
    await clearAllFields();
    setStatus(`Enviado a ${savedName} y limpiado.`, 'ok');
  } catch (err) {
    setStatus(`No se pudo conectar con ${baseUrl}`, 'err');
  } finally {
    saveBtn.disabled = false;
  }
}

async function lookupCurrentSite() {
  const baseUrl = getBaseUrl();
  const userId = getUserId();
  if (!userId) {
    setStatus('Ingresa el correo de tu cuenta primero.', 'err');
    userIdInput.focus();
    return;
  }
  await chrome.storage.local.set({ serverUrl: baseUrl, userId });
  listEl.innerHTML = '';
  setStatus(`Buscando en ${currentHost || 'este sitio'}...`);

  try {
    const res = await fetch(`${baseUrl}/api/vault/${encodeURIComponent(userId)}`);
    if (!res.ok) {
      setStatus(`Error del servidor (${res.status})`, 'err');
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
      setStatus('No hay credenciales guardadas para este sitio.');
      return;
    }

    setStatus(`${matches.length} coincidencia(s) encontradas.`, 'ok');
    for (const { client, page } of matches) {
      const card = document.createElement('div');
      card.className = 'match-card';
      card.innerHTML = `
        <div class="match-client">${escapeHtml(client.nombre || '')} • CC: ${escapeHtml(client.cc || '')}</div>
        <div class="match-site">${escapeHtml(page.siteName || page.url || 'Página')}</div>
        <div class="match-user">${escapeHtml(page.username || '')}</div>
        <div class="match-actions">
          <button class="btn-pill fill-btn">Autocompletar</button>
          <button class="btn-pill copy-btn">Copiar clave</button>
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
        setStatus('Autocompletado y vista limpiada.', 'ok');
      });
      card.querySelector('.copy-btn').addEventListener('click', async () => {
        await navigator.clipboard.writeText(page.password || '');
        listEl.innerHTML = '';
        setStatus('Clave copiada y vista limpiada.', 'ok');
      });
      listEl.appendChild(card);
    }
  } catch (err) {
    setStatus(`No se pudo conectar con ${baseUrl}`, 'err');
  }
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

settingsBtn.addEventListener('click', () => {
  settingsDrawer.classList.toggle('open');
});
togglePassBtn.addEventListener('click', () => {
  passwordInput.type = passwordInput.type === 'password' ? 'text' : 'password';
});
saveBtn.addEventListener('click', saveToAppAndClear);
lookupBtn.addEventListener('click', lookupCurrentSite);
clearBtn.addEventListener('click', async () => {
  await clearAllFields();
  setStatus('Datos eliminados de la extensión.');
});
init();
