const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const fs = require('fs-extra');
const { spawn } = require('child_process');

const isDev = !app.isPackaged;
const RESOURCES = isDev ? app.getAppPath() : process.resourcesPath;

let mainWindow;

const getResourcePath = (relativePath) => {
  if (isDev) {
    return path.join(__dirname, relativePath);
  }
  return path.join(RESOURCES, relativePath);
};

const getConfigPath = () => {
  const userDataPath = app.getPath('userData');
  return path.join(userDataPath, 'vigencias-config.json');
};

const getLogPath = () => {
  const userDataPath = app.getPath('userData');
  return path.join(userDataPath, 'logs');
};

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1200,
    minHeight: 700,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      enableRemoteModule: false,
      sandbox: true,
      preload: path.join(__dirname, 'preload.js'),
      webSecurity: true
    },
    show: false,
    titleBarStyle: 'default',
    autoHideMenuBar: true
  });

  if (isDev) {
    mainWindow.loadURL('http://localhost:5173');
    mainWindow.webContents.openDevTools();
  } else {
    const indexPath = path.join(RESOURCES, 'dist', 'index.html');
    mainWindow.loadFile(indexPath);
  }

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(async () => {
  const logDir = getLogPath();
  await fs.ensureDir(logDir);
  
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

function logMessage(level, message, data = null) {
  const timestamp = new Date().toISOString();
  const logEntry = {
    timestamp,
    level,
    message,
    data: data ? JSON.stringify(data, null, 2) : null
  };
  
  console.log(`[${timestamp}] [${level}] ${message}`, data || '');
  
  const logDir = getLogPath();
  const logFile = path.join(logDir, `vigencias-${new Date().toISOString().split('T')[0]}.log`);
  const logLine = `[${timestamp}] [${level}] ${message}${data ? ' ' + JSON.stringify(data) : ''}\n`;
  
  fs.appendFile(logFile, logLine).catch(err => {
    console.error('Error writing to log file:', err);
  });
  
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send('log-message', logEntry);
  }
}

async function executePowerShellScript(operation, params = {}) {
  return new Promise((resolve, reject) => {
    try {
      const scriptPath = getResourcePath('powershell-bridge/VigenciasProcessor.ps1');
      
      if (!fs.existsSync(scriptPath)) {
        throw new Error(`Script PowerShell no encontrado: ${scriptPath}`);
      }

      const args = [
        '-ExecutionPolicy', 'Bypass',
        '-NoProfile',
        '-WindowStyle', 'Hidden',
        '-File', scriptPath,
        '-Operation', operation
      ];

      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          args.push(`-${key}`);
          if (typeof value === 'object') {
            args.push(JSON.stringify(value));
          } else {
            args.push(value.toString());
          }
        }
      });

      logMessage('INFO', `Ejecutando PowerShell: ${operation}`, { args: args.slice(0, 6) });

      const powershell = spawn('powershell.exe', args, {
        stdio: ['pipe', 'pipe', 'pipe'],
        windowsHide: true,
        timeout: 600000,
        shell: false,
        cwd: getResourcePath('powershell-bridge')
      });

      let stdout = '';
      let stderr = '';

      powershell.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      powershell.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      powershell.on('close', (code) => {
        try {
          if (code === 0 && stdout.trim()) {
            const jsonBlocks = stdout.match(/\{(?:.|\r?\n)*\}/g);
            if (jsonBlocks && jsonBlocks.length > 0) {
              const lastJsonBlock = jsonBlocks[jsonBlocks.length - 1];
              const result = JSON.parse(lastJsonBlock);
              logMessage('SUCCESS', `PowerShell ${operation} completado`, { success: result.success });
              resolve(result);
            } else {
              resolve({ success: true, message: stdout.trim() });
            }
          } else {
            const errorMsg = stderr || `PowerShell termino con codigo ${code}`;
            logMessage('ERROR', `PowerShell ${operation} fallo`, { code, stderr: stderr.substring(0, 500) });
            resolve({ success: false, error: errorMsg });
          }
        } catch (parseError) {
          logMessage('ERROR', `Error parseando respuesta PowerShell`, { parseError: parseError.message, stdout: stdout.substring(0, 500) });
          resolve({ success: false, error: `Error parseando respuesta: ${parseError.message}` });
        }
      });

      powershell.on('error', (error) => {
        logMessage('ERROR', `Error ejecutando PowerShell`, error);
        resolve({ success: false, error: error.message });
      });

    } catch (error) {
      logMessage('ERROR', `Error preparando PowerShell`, error);
      reject(error);
    }
  });
}

ipcMain.handle('select-file', async (event, options = {}) => {
  try {
    const result = await dialog.showOpenDialog(mainWindow, {
      title: options.title || 'Seleccionar archivo',
      filters: options.filters || [
        { name: 'Todos los archivos', extensions: ['*'] }
      ],
      properties: ['openFile']
    });

    if (result.canceled) {
      return null;
    }

    return result.filePaths[0];
  } catch (error) {
    logMessage('ERROR', 'Error seleccionando archivo', error);
    throw error;
  }
});

ipcMain.handle('select-directory', async (event) => {
  try {
    const result = await dialog.showOpenDialog(mainWindow, {
      title: 'Seleccionar directorio',
      properties: ['openDirectory']
    });

    if (result.canceled) {
      return null;
    }

    return result.filePaths[0];
  } catch (error) {
    logMessage('ERROR', 'Error seleccionando directorio', error);
    throw error;
  }
});

ipcMain.handle('read-config', async (event) => {
  try {
    const configPath = getConfigPath();
    
    if (fs.existsSync(configPath)) {
      const config = await fs.readJson(configPath);
      logMessage('INFO', 'Configuracion cargada exitosamente');
      return config;
    }
    
    return null;
  } catch (error) {
    logMessage('ERROR', 'Error leyendo configuracion', error);
    throw error;
  }
});

ipcMain.handle('save-config', async (event, config) => {
  try {
    const configPath = getConfigPath();
    await fs.ensureDir(path.dirname(configPath));
    await fs.writeJson(configPath, config, { spaces: 2 });
    logMessage('INFO', 'Configuracion guardada exitosamente');
    return true;
  } catch (error) {
    logMessage('ERROR', 'Error guardando configuracion', error);
    throw error;
  }
});

ipcMain.handle('copy-database', async (event, sourcePath, destinationPath) => {
  try {
    return await executePowerShellScript('copy_database', {
      SourcePath: sourcePath,
      DestinationPath: destinationPath
    });
  } catch (error) {
    logMessage('ERROR', 'Error copiando base de datos', error);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('test-firebird-connection', async (event, config) => {
  try {
    return await executePowerShellScript('test_firebird_connection', {
      ConfigJson: JSON.stringify({ firebird: config })
    });
  } catch (error) {
    logMessage('ERROR', 'Error conectando Firebird', error);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('test-mysql-connection', async (event, config) => {
  try {
    return await executePowerShellScript('test_mysql_connection', {
      ConfigJson: JSON.stringify({ mysql: config })
    });
  } catch (error) {
    logMessage('ERROR', 'Error conectando MySQL', error);
    return { success: false, error: error.message };
  }
});

ipcMain.handle('process-vigencias', async (event, processConfig, pathConfig, dbConfig) => {
  try {
    return await executePowerShellScript('process_vigencias', {
      ConfigJson: JSON.stringify(dbConfig),
      OutputPath: pathConfig.outputPath,
      DiasFacturas: processConfig.diasFacturas,
      VigenciaDia: processConfig.vigenciaDia,
      VigenciaConvenio: processConfig.vigenciaConvenio,
      VigenciaCicloEscolar: processConfig.vigenciaCicloEscolar,
      PalabrasExcluidas: JSON.stringify(processConfig.palabrasExcluidas),
      PalabrasConvenio: JSON.stringify(processConfig.palabrasConvenio),
      PalabrasCicloEscolar: JSON.stringify(processConfig.palabrasCicloEscolar)
    });
  } catch (error) {
    logMessage('ERROR', 'Error procesando vigencias', error);
    return { 
      success: false, 
      error: error.message,
      facturasProcessed: 0,
      vigenciasUpdated: 0,
      registrosGenerados: 0,
      errors: [error.message],
      archivosGenerados: []
    };
  }
});

process.on('uncaughtException', (error) => {
  logMessage('CRITICAL', 'Excepcion no capturada', error);
  console.error('Uncaught Exception:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  logMessage('CRITICAL', 'Promesa rechazada no manejada', { reason, promise });
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

logMessage('INFO', 'Aplicacion iniciada', {
  version: app.getVersion(),
  platform: process.platform,
  arch: process.arch,
  isDev,
  isPackaged: app.isPackaged,
  electronVersion: process.versions.electron,
  nodeVersion: process.versions.node,
  resourcesPath: RESOURCES
});