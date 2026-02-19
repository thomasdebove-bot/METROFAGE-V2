Param(
    [string]$Python = "python",
    [string]$EntryPoint = "run_server.py",
    [string]$ExeName = "Metrofage",
    [string]$AssetsDir = "assets",
    [string]$IconPath = "",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

function Add-DataArg {
    param(
        [System.Collections.Generic.List[string]]$Args,
        [string]$Source,
        [string]$Dest
    )
    $Args.Add("--add-data")
    $Args.Add("$Source;$Dest")
}

try {
    if (-not (Test-Path $EntryPoint)) {
        throw "Entrée Python introuvable: $EntryPoint"
    }

    if (-not (Test-Path $AssetsDir)) {
        throw "Dossier assets introuvable: $AssetsDir"
    }

    $requiredLogos = @(
        "Logo EIFFAGE.png",
        "Carré eiffage.png",
        "Carré eiffage 90.png",
        "Logo TEMPO.png",
        "Rythme.png",
        "T logo.png",
        "QR CODE.png"
    )

    $missing = @()
    foreach ($logo in $requiredLogos) {
        $path = Join-Path $AssetsDir $logo
        if (-not (Test-Path $path)) {
            $missing += $path
        }
    }

    if ($missing.Count -gt 0) {
        throw "Logos manquants dans assets:`n - $($missing -join "`n - ")"
    }

    Write-Host "[1/3] Installation des dépendances de build..."
    & $Python -m pip install --upgrade pip pyinstaller | Out-Host

    Write-Host "[2/3] Génération de l'exécutable..."
    $args = [System.Collections.Generic.List[string]]::new()
    $args.Add("-m")
    $args.Add("PyInstaller")
    $args.Add("--noconfirm")
    $args.Add("--onefile")
    $args.Add("--name")
    $args.Add($ExeName)
    $args.Add("--collect-all")
    $args.Add("uvicorn")

    if ($Clean) {
        $args.Add("--clean")
    }

    if ($IconPath -and (Test-Path $IconPath)) {
        $args.Add("--icon")
        $args.Add($IconPath)
    }

    Add-DataArg -Args $args -Source (Join-Path $AssetsDir "Logo EIFFAGE.png") -Dest "assets"
    Add-DataArg -Args $args -Source (Join-Path $AssetsDir "Carré eiffage.png") -Dest "assets"
    Add-DataArg -Args $args -Source (Join-Path $AssetsDir "Carré eiffage 90.png") -Dest "assets"
    Add-DataArg -Args $args -Source (Join-Path $AssetsDir "Logo TEMPO.png") -Dest "assets"
    Add-DataArg -Args $args -Source (Join-Path $AssetsDir "Rythme.png") -Dest "assets"
    Add-DataArg -Args $args -Source (Join-Path $AssetsDir "T logo.png") -Dest "assets"
    Add-DataArg -Args $args -Source (Join-Path $AssetsDir "QR CODE.png") -Dest "assets"

    $args.Add($EntryPoint)

    & $Python @args | Out-Host

    Write-Host "[3/3] Build terminé. Exécutable: dist/$ExeName.exe"
    Write-Host "Lancez dist/$ExeName.exe : le serveur démarre sur http://127.0.0.1:8090 et ouvre le navigateur."
}
catch {
    Write-Host "Erreur pendant le build:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "\nAppuyez sur Entrée pour fermer..."
    [void](Read-Host)
    exit 1
}
