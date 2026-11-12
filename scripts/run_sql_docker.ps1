param(
    [string]$Container = "",
    [string]$SysPwd = "",
    [switch]$IncludeTests = $true,
    [switch]$IncludeOptimization = $true
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$SqlDir = Join-Path $ProjectRoot "sql"

# Doc .env neu co
$envFile = Join-Path $ProjectRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $k = $matches[1].Trim()
            $v = $matches[2].Trim()
            if ($k -eq "DOCKER_CONTAINER" -and -not $Container) { $Container = $v }
            if ($k -eq "ORACLE_PWD" -and -not $SysPwd) { $SysPwd = $v }
        }
    }
}

# Tu dong phat hien container oracle23ai hoac oracle23ai_ewallet dang chay
if (-not $Container) {
    $running = docker ps --format "{{.Names}}"
    if ($running -contains "oracle23ai") { $Container = "oracle23ai" }
    elseif ($running -contains "oracle23ai_ewallet") { $Container = "oracle23ai_ewallet" }
    else { $Container = "oracle23ai" }
}
if (-not $SysPwd) { $SysPwd = "huy08112006" }

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Chay toan bo script Oracle 23ai tren container: $Container" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

function Invoke-OracleSql {
    param(
        [string]$ConnString,
        [string]$LocalSqlPath
    )
    $fileName = Split-Path -Leaf $LocalSqlPath
    Write-Host "--> Dang chay $fileName ..." -ForegroundColor Yellow

    $sqlBody = Get-Content -Path $LocalSqlPath -Raw -Encoding UTF8
    $payload = @"
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET DEFINE OFF;
SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 220;
SET PAGESIZE 200;
$sqlBody

EXIT;
"@
    # Pipe UTF-8 script truc tiep qua docker exec (khong can mount thu muc vao container co san)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    $bytes = $utf8NoBom.GetBytes($payload.Replace("`r`n", "`n"))
    $tmpFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllBytes($tmpFile, $bytes)
    try {
        docker cp $tmpFile "${Container}:/tmp/run_step.sql" | Out-Null
        docker exec -e NLS_LANG=AMERICAN_AMERICA.AL32UTF8 $Container bash -c "sqlplus -s '$ConnString' @/tmp/run_step.sql"
        if ($LASTEXITCODE -ne 0) {
            throw "Loi khi chay $fileName (Exit code: $LASTEXITCODE)"
        }
    } finally {
        Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
    }
}

$sysConn = "sys/$SysPwd@//localhost:1521/FREEPDB1 as sysdba"
$appConn = "EWALLET_APP/Ewallet2026@//localhost:1521/FREEPDB1"

Invoke-OracleSql -ConnString $sysConn -LocalSqlPath (Join-Path $SqlDir "00_docker_sys_setup.sql")

$appScripts = @(
    "01_drop_objects.sql",
    "02_tables_constraints.sql",
    "03_sequences_indexes.sql",
    "04_seed_data.sql",
    "05_pkg_ngoai_le_vi.sql",
    "06_functions.sql",
    "07_pkg_quan_ly_vi.sql",
    "08_triggers.sql"
)

if ($IncludeTests) { $appScripts += "09_test_scenarios.sql" }
if ($IncludeOptimization) { $appScripts += "10_optimization_plans.sql" }

foreach ($s in $appScripts) {
    Invoke-OracleSql -ConnString $appConn -LocalSqlPath (Join-Path $SqlDir $s)
}

Write-Host "=================================================================" -ForegroundColor Green
Write-Host " Hoan tat chay toan bo SQL/PL-SQL tren Oracle Database 23ai!" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
