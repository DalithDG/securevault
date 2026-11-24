chrome.runtime.onInstalled.addListener(() => {
  console.log('SecureVault extension installed');
});

chrome.runtime.onMessage.addListener((msg, sender) => {
  if (msg.type === 'CAPTURE_CREDENTIALS') {
    chrome.storage.local.set({ pendingCredential: msg.payload });
    chrome.action.setBadgeText({ text: '1', tabId: sender.tab.id });
  }
});