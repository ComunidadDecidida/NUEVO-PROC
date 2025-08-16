import { DatabaseConfig, PathConfig, ProcessConfig, ProcessResult, ConnectionResult, DatabaseOperationResult } from '../types';

class DatabaseService {
  private isElectron: boolean;

  constructor() {
    this.isElectron = typeof window !== 'undefined' && window.electronAPI !== undefined;
  }

  async testFirebirdConnection(config: DatabaseConfig['firebird']): Promise<ConnectionResult> {
    try {
      if (this.isElectron && window.electronAPI?.testFirebirdConnection) {
        return await window.electronAPI.testFirebirdConnection(config);
      } else {
        console.warn('Firebird connection not available in web mode');
        return { success: false, error: 'Conexion Firebird no disponible en modo web' };
      }
    } catch (error) {
      console.error('Firebird connection test failed:', error);
      return { success: false, error: error.message };
    }
  }

  async testMySQLConnection(config: DatabaseConfig['mysql']): Promise<ConnectionResult> {
    try {
      if (this.isElectron && window.electronAPI?.testMySQLConnection) {
        return await window.electronAPI.testMySQLConnection(config);
      } else {
        console.warn('MySQL connection not available in web mode');
        return { success: false, error: 'Conexion MySQL no disponible en modo web' };
      }
    } catch (error) {
      console.error('MySQL connection test failed:', error);
      return { success: false, error: error.message };
    }
  }

  async copyDatabase(sourcePath: string, destinationPath: string): Promise<DatabaseOperationResult> {
    try {
      if (this.isElectron && window.electronAPI?.copyDatabase) {
        return await window.electronAPI.copyDatabase(sourcePath, destinationPath);
      } else {
        console.warn('Database copy not available in web mode');
        return { success: false, error: 'Copia de base de datos no disponible en modo web' };
      }
    } catch (error) {
      console.error('Database copy failed:', error);
      return { success: false, error: error.message };
    }
  }

  async processVigencias(
    processConfig: ProcessConfig, 
    pathConfig: PathConfig, 
    dbConfig: DatabaseConfig
  ): Promise<ProcessResult> {
    try {
      if (this.isElectron && window.electronAPI?.processVigencias) {
        return await window.electronAPI.processVigencias(processConfig, pathConfig, dbConfig);
      } else {
        console.warn('Vigencias processing not available in web mode');
        return {
          success: false,
          message: 'Procesamiento de vigencias no disponible en modo web',
          facturasProcessed: 0,
          vigenciasUpdated: 0,
          registrosGenerados: 0,
          errors: ['Funcionalidad no disponible en modo web'],
          archivosGenerados: []
        };
      }
    } catch (error) {
      console.error('Vigencias processing failed:', error);
      return {
        success: false,
        message: `Error procesando vigencias: ${error.message}`,
        facturasProcessed: 0,
        vigenciasUpdated: 0,
        registrosGenerados: 0,
        errors: [error.message],
        archivosGenerados: []
      };
    }
  }
}

export const databaseService = new DatabaseService();