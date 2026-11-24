chrome.runtime.onInstalled.addListener(() => {
  chrome.storage.local.remove(['clients', 'lastSync']);
});

chrome.runtime.onMessage.addListener((msg, sender) => {
  if (msg.type === 'CAPTURE_CREDENTIALS') {
    chrome.storage.local.set({ pendingCredential: msg.payload });
    if (sender.tab?.id) {
      chrome.action.setBadgeText({ text: '1', tabId: sender.tab.id });
    }
  }
});
