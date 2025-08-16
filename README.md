# Sistema de Gestion de Vigencias

## Descripcion
Sistema completo de gestion de vigencias que procesa informacion de bases de datos Firebird (SAE) y MySQL para generar archivos de vigencias automatizados.

## Caracteristicas Principales

### Funcionalidades Core
- **Copia automatica de base de datos** Firebird desde red a local
- **Extraccion de clientes** desde base de datos SAE (Firebird)
- **Actualizacion de clientes** en base de datos MySQL remota
- **Procesamiento de vigencias** con logica estricta configurable
- **Generacion de archivos** de salida automatizada
- **Programacion de ejecuciones** con multiples horarios diarios

### Tipos de Vigencias Soportados
1. **Vigencias Normales**: Basadas en cuota mantenimiento con deteccion de meses
2. **Vigencias Convenio**: 35 dias configurables desde fecha de factura
3. **Vigencias Ciclo Escolar**: 365 dias configurables desde fecha de factura

### Archivos Generados
- `Registros.txt`: Informacion extraida de facturas
- `Carga_Integra32.txt`: Archivo para sistema de control de acceso
- `Registros_Procesados.txt`: Log de registros procesados exitosamente

## Flujo de Funcionamiento

### 1. Copia de Base de Datos
- Copia archivo .fdb desde ruta de red configurada
- Utiliza la ruta local configurada como destino
- Verifica integridad de la copia

### 2. Extraccion de Informacion
- Conecta a base de datos Firebird local
- Extrae informacion de clientes usando IDSAE como clave
- Procesa facturas de los ultimos N dias configurables

### 3. Actualizacion MySQL
- Conecta a base de datos MySQL remota
- Actualiza/inserta clientes usando IDSAE como referencia
- Mantiene sincronizacion entre sistemas

### 4. Procesamiento de Vigencias
- Analiza observaciones de facturas
- Aplica logica estricta segun configuracion:
  - **Palabras excluidas**: Facturas que no se procesan
  - **Palabras convenio**: Vigencia de 35 dias
  - **Palabras ciclo escolar**: Vigencia de 365 dias
  - **Cuota mantenimiento**: Vigencia calculada por mes mayor + dia configurado

### 5. Generacion de Archivos
- Crea archivo `Registros.txt` con informacion extraida
- Genera `Carga_Integra32.txt` con formato especifico para control de acceso
- Produce `Registros_Procesados.txt` como log de procesamiento

## Configuracion

### Base de Datos Firebird (SAE Local)
- Host: localhost (tipicamente)
- Puerto: 3050
- Usuario: SYSDBA
- Contraseña: masterkey
- Ruta: Archivo .fdb local

### Base de Datos MySQL (Remota)
- Host: Servidor MySQL remoto
- Puerto: 3306
- Base de datos: Nombre de la base
- Credenciales de acceso

### Rutas de Archivos
- **Origen**: Ruta de red del archivo .fdb
- **Local**: Ruta local donde copiar el archivo
- **Salida**: Directorio para archivos generados

### Parametros de Proceso
- **Dias de facturas**: Cantidad de dias hacia atras para procesar
- **Dia de vigencia**: Dia del mes para vigencias normales (1-28)
- **Vigencia convenio**: Dias para vigencias de convenio
- **Vigencia ciclo escolar**: Dias para vigencias de ciclo escolar
- **Palabras de control**: Listas configurables para logica de procesamiento

### Programacion Automatica
- **Horarios multiples**: Varios horarios en el mismo dia
- **Dias de semana**: Seleccion de dias para ejecucion
- **Ejecucion automatica**: Sin intervencion manual

## Logica de Vigencias

### Vigencias Normales (Cuota Mantenimiento)
1. Busca año valido (igual o mayor al actual)
2. Identifica meses en observaciones (ej: "Diciembre a Marzo 2025")
3. Encuentra el mes mayor mencionado
4. Calcula vigencia: dia configurado del mes siguiente al mayor
5. Maneja cambio de año automaticamente

### Vigencias Convenio
- Detecta palabra "CONVENIO" en observaciones
- Asigna vigencia de 35 dias desde fecha de factura
- Procesa aun sin año valido

### Vigencias Ciclo Escolar
- Detecta palabras "CICLO ESCOLAR" en observaciones
- Asigna vigencia de 365 dias desde fecha de factura
- Procesa aun sin año valido

### Exclusiones
- Facturas con palabras excluidas no se procesan
- Lista configurable de palabras a excluir

## Instalacion y Uso

### Requisitos del Sistema
- Windows 10/11 x64
- .NET Framework 4.7.2 o superior
- PowerShell 5.1 o superior
- Acceso a bases de datos Firebird y MySQL

### Instalacion
1. Ejecutar instalador como Administrador
2. Configurar conexiones de base de datos
3. Establecer rutas de archivos
4. Configurar parametros de proceso
5. Probar conexiones antes del primer uso

### Uso Diario
1. **Manual**: Boton "Iniciar Proceso" en dashboard
2. **Automatico**: Configurar horarios en pestaña Parametros
3. **Monitoreo**: Seguimiento en tiempo real en pestaña Monitor
4. **Logs**: Revision de actividad en pestaña Logs

## Archivos de Salida

### Registros.txt
Formato CSV con informacion extraida:
```
IDSAE,FACTURA,FECHA,OBSERVACIONES,IMPORTE
CLI001,FAC001,2024-01-15,Cuota mantenimiento Enero 2024,1500.00
```

### Carga_Integra32.txt
Formato para sistema de control de acceso:
```
CardNumber,NIVEL ACCESO,FECHA EXPIRACION,
1016626954,1,6/1/2026,
1016941370,1,6/1/2026,
```

### Registros_Procesados.txt
Log detallado de procesamiento:
```
IDSAE,FACTURA,FECHA_FACTURA,OBSERVACIONES,VIGENCIA,TIPO
CLI001,FAC001,2024-01-15,Cuota mantenimiento Enero 2024,2024-02-09,NORMAL
```

## Compilacion como Ejecutable

### Preparacion
```bash
npm install
npm run build
```

### Compilacion
```bash
npm run dist
```

### Resultado
- Instalador: `Sistema de Gestion de Vigencias Setup-2.0.0-x64.exe`
- Ejecutable directo: En carpeta `win-unpacked/`

## Compatibilidad
- **Sistema Operativo**: Windows 10/11 x64
- **Bases de Datos**: Firebird 2.5+ y MySQL 5.7+
- **Arquitectura**: x64 exclusivamente
- **Permisos**: Requiere ejecucion como Administrador

## Soporte Tecnico
Para soporte tecnico y configuracion avanzada, consultar documentacion tecnica adicional o contactar al administrador del sistema.