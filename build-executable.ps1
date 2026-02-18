[CmdletBinding()]
param(
    [string]$PythonExe = "python",
    [string]$AppName = "metrofage",
    [switch]$Clean,
    [string]$Host = "0.0.0.0",
    [int]$Port = 8090,
    [switch]$EnableReload,
    [string]$MetronomeEntries,
    [string]$MetronomeMeetings,
    [string]$MetronomeCompanies,
    [string]$MetronomeProjects,
    [string]$MetronomeUsers,
    [string]$MetronomePackages,
    [string]$MetronomeDocuments,
    [string]$MetronomeComments,
    [string]$LogoEiffage,
    [string]$LogoEiffageSquare,
    [string]$LogoEiffageSquare90,
    [string]$LogoTempo,
    [string]$LogoRythme,
    [string]$LogoTMark,
    [string]$LogoQr
)

$ErrorActionPreference = "Stop"

function Invoke-Step {
    param([string]$Label, [scriptblock]$Script)
    Write-Host "`n==> $Label" -ForegroundColor Cyan
    & $Script
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$venvDir = Join-Path $root ".venv-build"
$venvPython = Join-Path $venvDir "Scripts\python.exe"

if ($Clean) {
    Invoke-Step "Nettoyage des artefacts" {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $root "build")
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue (Join-Path $root "dist")
        Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $root "*.spec")
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $venvDir
    }
}

Invoke-Step "Vérification de Python" {
    $null = Get-Command $PythonExe -ErrorAction Stop
}

if (-not (Test-Path $venvPython)) {
    Invoke-Step "Création de l'environnement virtuel" {
        & $PythonExe -m venv $venvDir
    }
} else {
    Write-Host "`n==> Environnement virtuel existant réutilisé: $venvDir" -ForegroundColor Cyan
}

Invoke-Step "Installation des dépendances de build" {
    & $venvPython -m pip install --upgrade pip
    & $venvPython -m pip install fastapi uvicorn pandas openpyxl pyinstaller
}

Invoke-Step "Build de l'exécutable" {
    & $venvPython -m PyInstaller --noconfirm --clean --onefile --name $AppName launcher.py
}

$distDir = Join-Path $root "dist"
if (-not (Test-Path $distDir)) {
    throw "Le dossier dist n'a pas été généré."
}

$configPath = Join-Path $distDir "$AppName.runtime.json"
$legacyConfigPath = Join-Path $distDir "metrofage.runtime.json"

$runtimeConfig = [ordered]@{
    metrofage = [ordered]@{
        host = $Host
        port = $Port
        reload = [bool]$EnableReload
    }
    metronome_env = [ordered]@{
        METRONOME_ENTRIES = $MetronomeEntries
        METRONOME_MEETINGS = $MetronomeMeetings
        METRONOME_COMPANIES = $MetronomeCompanies
        METRONOME_PROJECTS = $MetronomeProjects
        METRONOME_USERS = $MetronomeUsers
        METRONOME_PACKAGES = $MetronomePackages
        METRONOME_DOCUMENTS = $MetronomeDocuments
        METRONOME_COMMENTS = $MetronomeComments
        METRONOME_LOGO_EIFFAGE = $LogoEiffage
        METRONOME_LOGO_EIFFAGE_SQUARE = $LogoEiffageSquare
        METRONOME_LOGO_EIFFAGE_SQUARE_90 = $LogoEiffageSquare90
        METRONOME_LOGO = $LogoTempo
        METRONOME_LOGO_RYTHME = $LogoRythme
        METRONOME_LOGO_TMARK = $LogoTMark
        METRONOME_QR = $LogoQr
    }
}

Invoke-Step "Génération du fichier de configuration runtime" {
    $runtimeConfig | ConvertTo-Json -Depth 6 | Out-File -Encoding UTF8 $configPath
    if ($configPath -ne $legacyConfigPath) {
        Copy-Item -Force $configPath $legacyConfigPath
    }
}

$exePath = Join-Path $distDir "$AppName.exe"
if (-not (Test-Path $exePath)) {
    $exePath = Join-Path $distDir $AppName
}

if (-not (Test-Path $exePath)) {
    throw "L'exécutable attendu n'a pas été trouvé: $exePath"
}

Write-Host "`nBuild terminé." -ForegroundColor Green
Write-Host "Exécutable : $exePath"
Write-Host "Config      : $configPath"
Write-Host "`n➡️ Copiez le dossier 'dist' tel quel sur le poste cible puis lancez l'exécutable."
