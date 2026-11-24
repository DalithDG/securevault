function getCredentials() {
  const user = document.querySelector('input[type="email"], input[name*="user"], input[name*="login"], input[type="text"]');
  const pass = document.querySelector('input[type="password"]');
  return { username: user?.value || '', password: pass?.value || '', url: location.href };
}

document.addEventListener('submit', () => {
  const creds = getCredentials();
  if (creds.username && creds.password) {
    chrome.runtime.sendMessage({ type: 'CAPTURE_CREDENTIALS', payload: creds });
  }
});

function setNativeValue(el, value) {
  const setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value')?.set;
  if (setter) {
    setter.call(el, value);
  } else {
    el.value = value;
  }
  el.dispatchEvent(new Event('input', { bubbles: true }));
  el.dispatchEvent(new Event('change', { bubbles: true }));
}

chrome.runtime.onMessage.addListener((msg) => {
  if (msg.type === 'FILL_CREDENTIALS') {
    const user = document.querySelector('input[type="email"], input[name*="user"], input[name*="login"], input[type="text"]');
    const pass = document.querySelector('input[type="password"]');
    const username = msg.payload?.username ?? '';
    const password = msg.payload?.password ?? '';
    if (user && username) setNativeValue(user, username);
    if (pass && password) setNativeValue(pass, password);
  }
});
