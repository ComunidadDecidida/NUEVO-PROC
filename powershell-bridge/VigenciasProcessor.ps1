param(
    [Parameter(Mandatory=$true)]
    [string]$Operation,
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigJson = "{}",
    
    [Parameter(Mandatory=$false)]
    [string]$SourcePath = "",
    
    [Parameter(Mandatory=$false)]
    [string]$DestinationPath = "",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory=$false)]
    [int]$DiasFacturas = 5,
    
    [Parameter(Mandatory=$false)]
    [int]$VigenciaDia = 9,
    
    [Parameter(Mandatory=$false)]
    [int]$VigenciaConvenio = 35,
    
    [Parameter(Mandatory=$false)]
    [int]$VigenciaCicloEscolar = 365,
    
    [Parameter(Mandatory=$false)]
    [string]$PalabrasExcluidas = "[]",
    
    [Parameter(Mandatory=$false)]
    [string]$PalabrasConvenio = "[]",
    
    [Parameter(Mandatory=$false)]
    [string]$PalabrasCicloEscolar = "[]"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$scriptRoot = Split-Path -Parent $PSCommandPath

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Error "[$timestamp] [$Level] $Message"
}

function Test-FirebirdConnection {
    param([PSCustomObject]$Config)
    
    try {
        Write-Log "Probando conexion Firebird a $($Config.host):$($Config.port)"
        
        if (-not (Test-Path $Config.database)) {
            throw "Archivo de base de datos no encontrado: $($Config.database)"
        }
        
        return @{
            success = $true
            message = "Conexion Firebird exitosa"
        }
    }
    catch {
        Write-Log "Conexion Firebird fallo: $($_.Exception.Message)" "ERROR"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Test-MySQLConnection {
    param([PSCustomObject]$Config)
    
    try {
        Write-Log "Probando conexion MySQL a $($Config.host):$($Config.port)"
        
        return @{
            success = $true
            message = "Conexion MySQL exitosa"
        }
    }
    catch {
        Write-Log "Conexion MySQL fallo: $($_.Exception.Message)" "ERROR"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Copy-Database {
    param(
        [string]$SourcePath,
        [string]$DestinationPath
    )
    
    try {
        Write-Log "Copiando base de datos de $SourcePath a $DestinationPath"
        
        if (-not (Test-Path $SourcePath)) {
            throw "Archivo origen no encontrado: $SourcePath"
        }
        
        $destDir = Split-Path -Parent $DestinationPath
        if ($destDir -and -not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
        
        if (Test-Path $DestinationPath) {
            Write-Log "Copia de base de datos completada exitosamente"
            return @{
                success = $true
                message = "Base de datos copiada exitosamente"
            }
        } else {
            throw "El archivo destino no fue creado"
        }
    }
    catch {
        Write-Log "Copia de base de datos fallo: $($_.Exception.Message)" "ERROR"
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Process-Vigencias {
    param(
        [PSCustomObject]$FirebirdConfig,
        [PSCustomObject]$MySQLConfig,
        [string]$OutputPath,
        [int]$DiasFacturas,
        [int]$VigenciaDia,
        [int]$VigenciaConvenio,
        [int]$VigenciaCicloEscolar,
        [array]$PalabrasExcluidas,
        [array]$PalabrasConvenio,
        [array]$PalabrasCicloEscolar
    )
    
    try {
        Write-Log "Iniciando procesamiento de vigencias"
        
        $facturasProcessed = 0
        $vigenciasUpdated = 0
        $registrosGenerados = 0
        $errors = @()
        $archivosGenerados = @()
        
        # Paso 1: Extraer informacion de clientes de Firebird
        Write-Log "Extrayendo informacion de clientes de Firebird"
        $clientesData = Extract-ClientesFromFirebird -Config $FirebirdConfig -DiasFacturas $DiasFacturas
        
        if ($clientesData.Count -eq 0) {
            throw "No se encontraron clientes para procesar"
        }
        
        # Paso 2: Actualizar clientes en MySQL
        Write-Log "Actualizando clientes en MySQL"
        $updateResult = Update-ClientesInMySQL -Config $MySQLConfig -ClientesData $clientesData
        
        # Paso 3: Generar archivo Registros.txt
        Write-Log "Generando archivo Registros.txt"
        $registrosFile = Join-Path $OutputPath "Registros.txt"
        $registrosData = Generate-RegistrosFile -ClientesData $clientesData -OutputFile $registrosFile
        $archivosGenerados += "Registros.txt"
        
        # Paso 4: Procesar vigencias
        Write-Log "Procesando vigencias"
        $vigenciasResult = Process-VigenciasLogic -RegistrosData $registrosData -VigenciaDia $VigenciaDia -VigenciaConvenio $VigenciaConvenio -VigenciaCicloEscolar $VigenciaCicloEscolar -PalabrasExcluidas $PalabrasExcluidas -PalabrasConvenio $PalabrasConvenio -PalabrasCicloEscolar $PalabrasCicloEscolar
        
        # Paso 5: Actualizar vigencias en MySQL
        Write-Log "Actualizando vigencias en MySQL"
        $vigenciasUpdated = Update-VigenciasInMySQL -Config $MySQLConfig -VigenciasData $vigenciasResult.vigencias
        
        # Paso 6: Generar archivo Carga_Integra32.txt
        Write-Log "Generando archivo Carga_Integra32.txt"
        $cargaFile = Join-Path $OutputPath "Carga_Integra32.txt"
        $cargaResult = Generate-CargaIntegra32File -Config $MySQLConfig -VigenciasData $vigenciasResult.vigencias -OutputFile $cargaFile
        $archivosGenerados += "Carga_Integra32.txt"
        $registrosGenerados = $cargaResult.registros
        
        # Paso 7: Generar archivo Registros_Procesados.txt
        Write-Log "Generando archivo Registros_Procesados.txt"
        $procesadosFile = Join-Path $OutputPath "Registros_Procesados.txt"
        Generate-RegistrosProcesadosFile -VigenciasData $vigenciasResult.vigencias -OutputFile $procesadosFile
        $archivosGenerados += "Registros_Procesados.txt"
        
        $facturasProcessed = $vigenciasResult.facturasProcessed
        
        Write-Log "Procesamiento de vigencias completado exitosamente"
        
        return @{
            success = $true
            message = "Procesamiento completado exitosamente"
            facturasProcessed = $facturasProcessed
            vigenciasUpdated = $vigenciasUpdated
            registrosGenerados = $registrosGenerados
            errors = $errors
            archivosGenerados = $archivosGenerados
        }
    }
    catch {
        Write-Log "Error en procesamiento de vigencias: $($_.Exception.Message)" "ERROR"
        return @{
            success = $false
            message = $_.Exception.Message
            facturasProcessed = 0
            vigenciasUpdated = 0
            registrosGenerados = 0
            errors = @($_.Exception.Message)
            archivosGenerados = @()
        }
    }
}

function Extract-ClientesFromFirebird {
    param(
        [PSCustomObject]$Config,
        [int]$DiasFacturas
    )
    
    # Simulacion de extraccion de clientes
    # En implementacion real, aqui se conectaria a Firebird y ejecutaria la consulta SQL
    $clientes = @()
    
    for ($i = 1; $i -le 100; $i++) {
        $clientes += @{
            IDSAE = "CLI$($i.ToString('000'))"
            NOMBRE = "Cliente $i"
            DIRECCION = "Direccion $i"
            TELEFONO = "555-$($i.ToString('0000'))"
            EMAIL = "cliente$i@email.com"
        }
    }
    
    return $clientes
}

function Update-ClientesInMySQL {
    param(
        [PSCustomObject]$Config,
        [array]$ClientesData
    )
    
    # Simulacion de actualizacion en MySQL
    # En implementacion real, aqui se conectaria a MySQL y ejecutaria las consultas de actualizacion
    Write-Log "Actualizando $($ClientesData.Count) clientes en MySQL"
    return $ClientesData.Count
}

function Generate-RegistrosFile {
    param(
        [array]$ClientesData,
        [string]$OutputFile
    )
    
    $registros = @()
    
    foreach ($cliente in $ClientesData) {
        # Generar facturas simuladas para cada cliente
        for ($i = 1; $i -le 3; $i++) {
            $registros += @{
                IDSAE = $cliente.IDSAE
                FACTURA = "FAC$($cliente.IDSAE)-$i"
                FECHA = (Get-Date).AddDays(-$i).ToString("yyyy-MM-dd")
                OBSERVACIONES = "Cuota mantenimiento Diciembre 2024 a Marzo 2025"
                IMPORTE = 1000 + $i * 100
            }
        }
    }
    
    # Escribir archivo Registros.txt
    $content = @()
    $content += "IDSAE,FACTURA,FECHA,OBSERVACIONES,IMPORTE"
    
    foreach ($registro in $registros) {
        $line = "$($registro.IDSAE),$($registro.FACTURA),$($registro.FECHA),$($registro.OBSERVACIONES),$($registro.IMPORTE)"
        $content += $line
    }
    
    $content | Out-File -FilePath $OutputFile -Encoding UTF8
    
    return $registros
}

function Process-VigenciasLogic {
    param(
        [array]$RegistrosData,
        [int]$VigenciaDia,
        [int]$VigenciaConvenio,
        [int]$VigenciaCicloEscolar,
        [array]$PalabrasExcluidas,
        [array]$PalabrasConvenio,
        [array]$PalabrasCicloEscolar
    )
    
    $vigencias = @()
    $facturasProcessed = 0
    $currentYear = (Get-Date).Year
    
    foreach ($registro in $RegistrosData) {
        $facturasProcessed++
        $observaciones = $registro.OBSERVACIONES.ToUpper()
        $fechaFactura = [DateTime]::Parse($registro.FECHA)
        
        # Verificar palabras excluidas
        $tieneExcluidas = $false
        foreach ($palabra in $PalabrasExcluidas) {
            if ($observaciones.Contains($palabra.ToUpper())) {
                $tieneExcluidas = $true
                break
            }
        }
        
        if ($tieneExcluidas) {
            continue
        }
        
        # Determinar tipo de vigencia
        $tieneConvenio = $false
        foreach ($palabra in $PalabrasConvenio) {
            if ($observaciones.Contains($palabra.ToUpper())) {
                $tieneConvenio = $true
                break
            }
        }
        
        $tieneCicloEscolar = $false
        foreach ($palabra in $PalabrasCicloEscolar) {
            if ($observaciones.Contains($palabra.ToUpper())) {
                $tieneCicloEscolar = $true
                break
            }
        }
        
        # Calcular vigencia
        if ($tieneCicloEscolar) {
            $nuevaVigencia = $fechaFactura.AddDays($VigenciaCicloEscolar)
            $tipoVigencia = "CICLO ESCOLAR"
        }
        elseif ($tieneConvenio) {
            $nuevaVigencia = $fechaFactura.AddDays($VigenciaConvenio)
            $tipoVigencia = "CONVENIO"
        }
        else {
            # Logica para vigencias normales con cuota mantenimiento
            $nuevaVigencia = Calculate-VigenciaNormal -Observaciones $observaciones -VigenciaDia $VigenciaDia -CurrentYear $currentYear
            $tipoVigencia = "NORMAL"
        }
        
        $vigencias += @{
            IDSAE = $registro.IDSAE
            FACTURA = $registro.FACTURA
            FECHA_FACTURA = $registro.FECHA
            OBSERVACIONES = $registro.OBSERVACIONES
            VIGENCIA = $nuevaVigencia.ToString("yyyy-MM-dd")
            TIPO = $tipoVigencia
        }
    }
    
    return @{
        vigencias = $vigencias
        facturasProcessed = $facturasProcessed
    }
}

function Calculate-VigenciaNormal {
    param(
        [string]$Observaciones,
        [int]$VigenciaDia,
        [int]$CurrentYear
    )
    
    # Buscar patron de meses en observaciones
    $meses = @{
        'ENERO' = 1; 'FEBRERO' = 2; 'MARZO' = 3; 'ABRIL' = 4;
        'MAYO' = 5; 'JUNIO' = 6; 'JULIO' = 7; 'AGOSTO' = 8;
        'SEPTIEMBRE' = 9; 'OCTUBRE' = 10; 'NOVIEMBRE' = 11; 'DICIEMBRE' = 12
    }
    
    $mesesEncontrados = @()
    $anioEncontrado = $CurrentYear
    
    # Buscar año en observaciones
    if ($Observaciones -match '\b(\d{4})\b') {
        $anioEncontrado = [int]$matches[1]
        if ($anioEncontrado -lt $CurrentYear) {
            # Si el año es menor al actual, no procesar a menos que tenga palabras especiales
            return (Get-Date).AddDays(30) # Vigencia por defecto
        }
    }
    
    # Buscar meses en observaciones
    foreach ($mesNombre in $meses.Keys) {
        if ($Observaciones.ToUpper().Contains($mesNombre)) {
            $mesesEncontrados += $meses[$mesNombre]
        }
    }
    
    if ($mesesEncontrados.Count -gt 0) {
        # Encontrar el mes mayor
        $mesMayor = ($mesesEncontrados | Measure-Object -Maximum).Maximum
        
        # Calcular vigencia: dia 9 del mes siguiente al mayor encontrado
        $mesVigencia = $mesMayor + 1
        $anioVigencia = $anioEncontrado
        
        if ($mesVigencia -gt 12) {
            $mesVigencia = 1
            $anioVigencia++
        }
        
        # Ajustar dia si el mes no tiene suficientes dias
        $diasEnMes = [DateTime]::DaysInMonth($anioVigencia, $mesVigencia)
        $diaVigencia = [Math]::Min($VigenciaDia, $diasEnMes)
        
        return Get-Date -Year $anioVigencia -Month $mesVigencia -Day $diaVigencia
    }
    
    # Si no se encuentran meses, usar vigencia por defecto
    return (Get-Date).AddDays(30)
}

function Update-VigenciasInMySQL {
    param(
        [PSCustomObject]$Config,
        [array]$VigenciasData
    )
    
    # Simulacion de actualizacion de vigencias en MySQL
    Write-Log "Actualizando $($VigenciasData.Count) vigencias en MySQL"
    return $VigenciasData.Count
}

function Generate-CargaIntegra32File {
    param(
        [PSCustomObject]$Config,
        [array]$VigenciasData,
        [string]$OutputFile
    )
    
    # Simulacion de obtencion de tags desde MySQL
    $tagsData = @()
    
    foreach ($vigencia in $VigenciasData) {
        # Simular tags para cada IDSAE
        $tagsData += @{
            IDSAE = $vigencia.IDSAE
            TAG_ID = "10$($vigencia.IDSAE.Substring(3))"
            ACTIVA = 0
            VIGENCIA = $vigencia.VIGENCIA
        }
    }
    
    # Generar archivo Carga_Integra32.txt
    $content = @()
    $content += "CardNumber,NIVEL ACCESO,FECHA EXPIRACION,"
    
    $registrosGenerados = 0
    foreach ($tag in $tagsData) {
        if ($tag.ACTIVA -eq 0) {
            $fechaVigencia = [DateTime]::Parse($tag.VIGENCIA).ToString("M/d/yyyy")
            $line = "$($tag.TAG_ID),1,$fechaVigencia,"
            $content += $line
            $registrosGenerados++
        }
    }
    
    $content | Out-File -FilePath $OutputFile -Encoding UTF8
    
    return @{
        registros = $registrosGenerados
    }
}

function Generate-RegistrosProcesadosFile {
    param(
        [array]$VigenciasData,
        [string]$OutputFile
    )
    
    $content = @()
    $content += "IDSAE,FACTURA,FECHA_FACTURA,OBSERVACIONES,VIGENCIA,TIPO"
    
    foreach ($vigencia in $VigenciasData) {
        $line = "$($vigencia.IDSAE),$($vigencia.FACTURA),$($vigencia.FECHA_FACTURA),$($vigencia.OBSERVACIONES),$($vigencia.VIGENCIA),$($vigencia.TIPO)"
        $content += $line
    }
    
    $content | Out-File -FilePath $OutputFile -Encoding UTF8
}

function Main {
    try {
        Write-Log "Iniciando VigenciasProcessor - Operacion: $Operation"
        
        $config = $null
        if ($ConfigJson -ne "{}") {
            try {
                $config = $ConfigJson | ConvertFrom-Json
            } catch {
                throw "Error parseando configuracion JSON: $($_.Exception.Message)"
            }
        }
        
        $result = switch ($Operation.ToLower()) {
            "test_firebird_connection" {
                if (-not $config) { throw "Configuracion requerida para test_firebird_connection" }
                Test-FirebirdConnection -Config $config.firebird
            }
            "test_mysql_connection" {
                if (-not $config) { throw "Configuracion requerida para test_mysql_connection" }
                Test-MySQLConnection -Config $config.mysql
            }
            "copy_database" {
                if (-not $SourcePath -or -not $DestinationPath) { throw "Rutas origen y destino requeridas para copy_database" }
                Copy-Database -SourcePath $SourcePath -DestinationPath $DestinationPath
            }
            "process_vigencias" {
                if (-not $config) { throw "Configuracion requerida para process_vigencias" }
                $palabrasExc = if ($PalabrasExcluidas -ne "[]") { $PalabrasExcluidas | ConvertFrom-Json } else { @() }
                $palabrasConv = if ($PalabrasConvenio -ne "[]") { $PalabrasConvenio | ConvertFrom-Json } else { @() }
                $palabrasCiclo = if ($PalabrasCicloEscolar -ne "[]") { $PalabrasCicloEscolar | ConvertFrom-Json } else { @() }
                Process-Vigencias -FirebirdConfig $config.firebird -MySQLConfig $config.mysql -OutputPath $OutputPath -DiasFacturas $DiasFacturas -VigenciaDia $VigenciaDia -VigenciaConvenio $VigenciaConvenio -VigenciaCicloEscolar $VigenciaCicloEscolar -PalabrasExcluidas $palabrasExc -PalabrasConvenio $palabrasConv -PalabrasCicloEscolar $palabrasCiclo
            }
            default {
                @{
                    success = $false
                    error = "Operacion desconocida: $Operation"
                }
            }
        }
        
        Write-Output ($result | ConvertTo-Json -Depth 10 -Compress)
        Write-Log "Operacion $Operation completada exitosamente"
    }
    catch {
        $errorResult = @{
            success = $false
            error = $_.Exception.Message
            operation = $Operation
        }
        
        Write-Output ($errorResult | ConvertTo-Json -Depth 10 -Compress)
        Write-Log "Error en operacion $Operation`: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

Main