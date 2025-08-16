const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  selectFile: (options) => ipcRenderer.invoke('select-file', options),
  selectDirectory: () => ipcRenderer.invoke('select-directory'),
  
  readConfig: () => ipcRenderer.invoke('read-config'),
  saveConfig: (config) => ipcRenderer.invoke('save-config', config),
  
  copyDatabase: (source, destination) => ipcRenderer.invoke('copy-database', source, destination),
  
  testFirebirdConnection: (config) => ipcRenderer.invoke('test-firebird-connection', config),
  testMySQLConnection: (config) => ipcRenderer.invoke('test-mysql-connection', config),
  
  processVigencias: (processConfig, pathConfig, dbConfig) => ipcRenderer.invoke('process-vigencias', processConfig, pathConfig, dbConfig),
  
  onLogMessage: (callback) => {
    ipcRenderer.on('log-message', (event, logEntry) => callback(logEntry));
  },
  
  removeAllListeners: (channel) => {
    ipcRenderer.removeAllListeners(channel);
  }
});

delete window.require;
delete window.exports;
delete window.module;