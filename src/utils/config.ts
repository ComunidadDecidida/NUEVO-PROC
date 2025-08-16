import { DatabaseConfig, PathConfig, ProcessConfig } from '../types';

export interface AppConfig {
  database: DatabaseConfig;
  paths: PathConfig;
  process: ProcessConfig;
  lastUpdated: string;
}

const DEFAULT_CONFIG: AppConfig = {
  database: {
    firebird: {
      host: 'localhost',
      database: 'C:\\SAE\\SAE90EMPRE01.FDB',
      user: 'SYSDBA',
      password: 'masterkey',
      port: '3050'
    },
    mysql: {
      host: 'localhost',
      port: '3306',
      database: 'vigencias_db',
      user: 'root',
      password: ''
    }
  },
  paths: {
    sourceDbPath: 'Z:\\SAE\\SAE90EMPRE01.FDB',
    localDbPath: 'C:\\SAE\\SAE90EMPRE01.FDB',
    outputPath: 'C:\\Vigencias\\'
  },
  process: {
    diasFacturas: 5,
    vigenciaDia: 9,
    vigenciaConvenio: 35,
    vigenciaCicloEscolar: 365,
    palabrasExcluidas: ['FONDO DE RESERVA', 'FONDO', 'INSCRIP', 'INSCRIPCION', 'ADELANTO', 'TARJETA', 'TARJE', 'ACCESO', 'TAG', 'APP'],
    palabrasConvenio: ['CONVENIO'],
    palabrasCicloEscolar: ['CICLO ESCOLAR'],
    scheduledExecution: {
      enabled: false,
      times: ['09:00'],
      days: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'],
      lastExecution: null
    }
  },
  lastUpdated: new Date().toISOString()
};

class ConfigManager {
  private isElectron: boolean;

  constructor() {
    this.isElectron = typeof window !== 'undefined' && window.electronAPI !== undefined;
  }

  async loadConfig(): Promise<AppConfig> {
    try {
      if (this.isElectron && window.electronAPI?.readConfig) {
        const config = await window.electronAPI.readConfig();
        return config ? { ...DEFAULT_CONFIG, ...config } : DEFAULT_CONFIG;
      } else {
        const stored = localStorage.getItem('vigencias-config');
        if (stored) {
          const parsed = JSON.parse(stored);
          return { ...DEFAULT_CONFIG, ...parsed };
        }
      }
    } catch (error) {
      console.error('Error loading config:', error);
    }
    return DEFAULT_CONFIG;
  }

  async saveConfig(config: AppConfig): Promise<void> {
    try {
      const configToSave = {
        ...config,
        lastUpdated: new Date().toISOString()
      };

      if (this.isElectron && window.electronAPI?.saveConfig) {
        await window.electronAPI.saveConfig(configToSave);
      } else {
        localStorage.setItem('vigencias-config', JSON.stringify(configToSave));
      }
    } catch (error) {
      console.error('Error saving config:', error);
      throw error;
    }
  }
}

export const configManager = new ConfigManager();