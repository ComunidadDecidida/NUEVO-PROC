export interface ElectronAPI {
  selectFile: (options?: any) => Promise<string | null>;
  selectDirectory: () => Promise<string | null>;
  readConfig: () => Promise<any>;
  saveConfig: (config: any) => Promise<void>;
  copyDatabase: (source: string, destination: string) => Promise<DatabaseOperationResult>;
  processVigencias: (config: ProcessConfig, paths: PathConfig, dbConfig: DatabaseConfig) => Promise<ProcessResult>;
  testFirebirdConnection: (config: FirebirdConfig) => Promise<ConnectionResult>;
  testMySQLConnection: (config: MySQLConfig) => Promise<ConnectionResult>;
}

export interface DatabaseConfig {
  firebird: FirebirdConfig;
  mysql: MySQLConfig;
}

export interface FirebirdConfig {
  host: string;
  database: string;
  user: string;
  password: string;
  port: string;
}

export interface MySQLConfig {
  host: string;
  port: string;
  database: string;
  user: string;
  password: string;
}

export interface PathConfig {
  sourceDbPath: string;
  localDbPath: string;
  outputPath: string;
}

export interface ProcessConfig {
  diasFacturas: number;
  vigenciaDia: number;
  vigenciaConvenio: number;
  vigenciaCicloEscolar: number;
  palabrasExcluidas: string[];
  palabrasConvenio: string[];
  palabrasCicloEscolar: string[];
  scheduledExecution: {
    enabled: boolean;
    times: string[];
    days: string[];
    lastExecution: string | null;
  };
}

export interface ProcessLog {
  id: string;
  timestamp: string;
  process: string;
  message: string;
  status: 'success' | 'error' | 'warning' | 'info';
}

export interface ProcessStatus {
  isRunning: boolean;
  currentStep: string;
  progress: number;
  lastRun: string | null;
}

export interface ProcessResult {
  success: boolean;
  message: string;
  facturasProcessed: number;
  vigenciasUpdated: number;
  registrosGenerados: number;
  errors: string[];
  archivosGenerados: string[];
}

export interface ConnectionResult {
  success: boolean;
  message?: string;
  error?: string;
}

export interface DatabaseOperationResult {
  success: boolean;
  message?: string;
  error?: string;
}

declare global {
  interface Window {
    electronAPI?: ElectronAPI;
  }
}