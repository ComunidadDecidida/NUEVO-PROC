# INSTRUCTIVO DE COMPILACION - Sistema de Gestion de Vigencias

## REQUISITOS PREVIOS

### Software Necesario
1. **Node.js 18.19.0 o superior**
   - Descargar desde: https://nodejs.org/
   - Instalar version LTS recomendada
   - Verificar: `node --version` y `npm --version`

2. **PowerShell 5.1 o superior**
   - Incluido en Windows 10/11
   - Verificar: `$PSVersionTable.PSVersion`

3. **Git (opcional)**
   - Para clonar repositorio
   - Descargar desde: https://git-scm.com/

### Permisos del Sistema
- Ejecutar PowerShell como Administrador
- Configurar politica de ejecucion:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
```

## PROCESO DE COMPILACION

### 1. Preparar Proyecto
```bash
# Clonar o descargar proyecto
git clone [URL_REPOSITORIO]
cd sistema-gestion-vigencias

# O descargar ZIP y extraer
```

### 2. Instalar Dependencias
```bash
# Limpiar cache
npm cache clean --force

# Instalar dependencias
npm install

# Verificar instalacion
npm list --depth=0
```

### 3. Compilar Aplicacion
```bash
# Limpiar proyecto
npm run clean

# Construir aplicacion web
npm run build

# Compilar ejecutable Windows
npm run dist
```

### 4. Verificar Resultado
```
release/
├── Sistema de Gestion de Vigencias Setup-2.0.0-x64.exe  # Instalador
└── win-unpacked/                                        # Ejecutable directo
    ├── Sistema de Gestion de Vigencias.exe             # Aplicacion principal
    └── resources/
        ├── app.asar                                     # Codigo aplicacion
        ├── dist/                                        # Web compilada
        └── powershell-bridge/                           # Scripts PowerShell
            └── VigenciasProcessor.ps1                   # Script principal
```

## INSTALACION EN SISTEMA DESTINO

### Requisitos del Sistema Destino
- Windows 10/11 x64
- .NET Framework 4.7.2 o superior
- PowerShell 5.1 o superior
- Permisos de Administrador

### Proceso de Instalacion
1. **Ejecutar instalador como Administrador**
   ```
   Sistema de Gestion de Vigencias Setup-2.0.0-x64.exe
   ```

2. **Seguir asistente de instalacion**
   - Aceptar terminos y condiciones
   - Seleccionar directorio de instalacion
   - Crear accesos directos

3. **Primera ejecucion**
   - Ejecutar como Administrador
   - Configurar conexiones de base de datos
   - Establecer rutas de archivos
   - Probar conexiones

## CONFIGURACION INICIAL

### 1. Base de Datos Firebird
```
Host: localhost
Puerto: 3050
Usuario: SYSDBA
Contraseña: masterkey
Base de datos: C:\SAE\SAE90EMPRE01.FDB
```

### 2. Base de Datos MySQL
```
Host: [servidor-mysql]
Puerto: 3306
Base de datos: vigencias_db
Usuario: [usuario]
Contraseña: [contraseña]
```

### 3. Rutas de Archivos
```
Origen (Red): Z:\SAE\SAE90EMPRE01.FDB
Local: C:\SAE\SAE90EMPRE01.FDB
Salida: C:\Vigencias\
```

### 4. Parametros de Proceso
```
Dias de facturas: 5
Dia de vigencia: 9
Vigencia convenio: 35 dias
Vigencia ciclo escolar: 365 dias
```

## SOLUCION DE PROBLEMAS

### Error: "PowerShell execution policy"
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
```

### Error: "electron-builder failed"
```bash
npm run full-clean
npm install
npm run build
npm run dist
```

### Error: "Access denied"
- Ejecutar terminal como Administrador
- Verificar permisos en directorio del proyecto
- Desactivar antivirus temporalmente

### Ejecutable no inicia
- Ejecutar como Administrador
- Verificar logs en: `%APPDATA%\sistema-gestion-vigencias\logs\`
- Comprobar dependencias del sistema

## VERIFICACION DE FUNCIONAMIENTO

### Checklist Pre-Compilacion
- [ ] Node.js 18.19.0+ instalado
- [ ] PowerShell ExecutionPolicy configurado
- [ ] `npm install` exitoso
- [ ] `npm run build` exitoso
- [ ] Sin errores en consola

### Checklist Post-Compilacion
- [ ] Instalador generado correctamente
- [ ] Ejecutable inicia sin errores
- [ ] Interfaz web carga correctamente
- [ ] Scripts PowerShell funcionan
- [ ] Conexiones de base de datos operativas

### Comandos de Diagnostico
```powershell
# Informacion del sistema
echo "OS: $([Environment]::OSVersion.VersionString)"
echo "Node.js: $(node --version)"
echo "PowerShell: $($PSVersionTable.PSVersion)"

# Verificar build
npm run build 2>&1 | Tee-Object -FilePath "build.log"

# Verificar compilacion
npm run dist 2>&1 | Tee-Object -FilePath "dist.log"
```

## DISTRIBUCION

### Instalador (Recomendado)
- Archivo: `Sistema de Gestion de Vigencias Setup-2.0.0-x64.exe`
- Instala automaticamente en Program Files
- Configura permisos de administrador
- Crea accesos directos

### Ejecutable Portable
- Carpeta: `win-unpacked/`
- Copiar toda la carpeta al sistema destino
- Ejecutar como Administrador
- No requiere instalacion

## RESULTADO FINAL

Al completar este instructivo tendras:
- Ejecutable Windows x64 completamente funcional
- Scripts PowerShell integrados y optimizados
- Instalador profesional con permisos automaticos
- Sistema listo para distribucion empresarial

El ejecutable resultante sera completamente independiente y listo para uso en entornos de produccion.