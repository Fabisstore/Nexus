const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('nexus', {
  getConfig: () => ipcRenderer.invoke('config:get'),
  openExternal: (url) => ipcRenderer.invoke('external:open', url),
  saveConfig: (config) => ipcRenderer.invoke('config:save', config),
  updates: {
    check: () => ipcRenderer.invoke('update:check'),
    download: () => ipcRenderer.invoke('update:download'),
    install: () => ipcRenderer.invoke('update:install'),
    onAvailable: (cb) => ipcRenderer.on('update:available', (_e, data) => cb(data)),
    onDownloaded: (cb) => ipcRenderer.on('update:downloaded', (_e, data) => cb(data)),
    onError: (cb) => ipcRenderer.on('update:error', (_e, data) => cb(data))
  }
});
