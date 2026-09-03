const { app, BrowserWindow, ipcMain, session } = require('electron');
const { autoUpdater } = require('electron-updater');
const path = require('path');
const fs = require('fs');

const configPath = path.join(app.getPath('userData'), 'supabase-config.json');

function readConfig() {
  try {
    return JSON.parse(fs.readFileSync(configPath, 'utf8'));
  } catch {
    try {
      return JSON.parse(fs.readFileSync(path.join(__dirname, 'supabase-config.json'), 'utf8'));
    } catch {
      return { url: '', publishableKey: '' };
    }
  }
}

function saveConfig(config) {
  const safe = {
    url: String(config?.url || '').trim(),
    publishableKey: String(config?.publishableKey || '').trim()
  };
  fs.mkdirSync(path.dirname(configPath), { recursive: true });
  fs.writeFileSync(configPath, JSON.stringify(safe, null, 2), 'utf8');
  return true;
}

ipcMain.handle('config:get', () => readConfig());
ipcMain.handle('config:save', (_event, config) => saveConfig(config));

function setupAutoUpdates(win) {
  autoUpdater.autoDownload = false;
  autoUpdater.autoInstallOnAppQuit = true;
  autoUpdater.on('update-available', (info) => win.webContents.send('update:available', { version: info.version }));
  autoUpdater.on('update-downloaded', (info) => win.webContents.send('update:downloaded', { version: info.version }));
  autoUpdater.on('error', (err) => win.webContents.send('update:error', { message: String(err?.message || err) }));
  ipcMain.handle('update:check', async () => {
    try { const result = await autoUpdater.checkForUpdates(); return { ok: true, updateInfo: result?.updateInfo || null }; }
    catch (e) { return { ok: false, error: String(e?.message || e) }; }
  });
  ipcMain.handle('update:download', async () => {
    try { await autoUpdater.downloadUpdate(); return { ok: true }; }
    catch (e) { return { ok: false, error: String(e?.message || e) }; }
  });
  ipcMain.handle('update:install', () => { autoUpdater.quitAndInstall(false, true); return true; });
  if (app.isPackaged) setTimeout(() => autoUpdater.checkForUpdates().catch(() => {}), 5000);
}

function createWindow() {
  const win = new BrowserWindow({
    width: 1440,
    height: 900,
    minWidth: 1000,
    minHeight: 650,
    title: 'Nexus by Fabisstore',
    icon: path.join(__dirname, 'assets', 'nexus.ico'),
    backgroundColor: '#080d14',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  });
  win.loadFile(path.join(__dirname, 'index.html'));
  setupAutoUpdates(win);
}

app.whenReady().then(() => {
  session.defaultSession.setPermissionRequestHandler((_webContents, permission, callback) => {
    callback(['media','display-capture','notifications'].includes(permission));
  });
  createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
