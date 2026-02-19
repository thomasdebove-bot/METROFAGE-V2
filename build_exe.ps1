Param(
    [string]$Python = "python",
    [string]$EntryPoint = "run_server.py",
    [string]$ExeName = "Metrofage",
    [string]$AssetsDir = "assets",
    [string]$TempoCrAssetsDir = "C:\tempo-cr\assets",
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

function Resolve-LogoSource {
    param(
        [string]$FileName,
        [string]$EnvVarName,
        [string[]]$FallbackCandidates
    )

    $candidates = [System.Collections.Generic.List[string]]::new()

    if ($EnvVarName) {
        $envValue = [Environment]::GetEnvironmentVariable($EnvVarName)
        if ($envValue) { $candidates.Add($envValue) }
    }

    foreach ($candidate in $FallbackCandidates) {
        if ($candidate) { $candidates.Add($candidate) }
    }

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

try {
    if (-not (Test-Path $EntryPoint)) {
        throw "Entrée Python introuvable: $EntryPoint"
    }

    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    if (-not $scriptRoot) { $scriptRoot = (Get-Location).Path }

    $effectiveAssetsDir = $AssetsDir

    # Résolution robuste du dossier assets:
    # - chemin absolu fourni
    # - chemin relatif au dossier du script
    # - fallback explicite C:\tempo-cr\assets
    if (-not [System.IO.Path]::IsPathRooted($effectiveAssetsDir)) {
        $candidateFromScript = Join-Path $scriptRoot $effectiveAssetsDir
        if (Test-Path $candidateFromScript) {
            $effectiveAssetsDir = $candidateFromScript
        }
    }

    if (-not (Test-Path $effectiveAssetsDir) -and (Test-Path $TempoCrAssetsDir)) {
        $effectiveAssetsDir = $TempoCrAssetsDir
    }
    $requiredLogos = @(
        @{ Name = "Logo EIFFAGE.png"; Env = "METRONOME_LOGO_EIFFAGE"; Default = "C:\tempo-cr\Logo EIFFAGE.png" },
        @{ Name = "Carré eiffage.png"; Env = "METRONOME_LOGO_EIFFAGE_SQUARE"; Default = "C:\tempo-cr\Carré eiffage.png" },
        @{ Name = "Carré eiffage 90.png"; Env = "METRONOME_LOGO_EIFFAGE_SQUARE_90"; Default = "C:\tempo-cr\Carré eiffage 90.png" },
        @{ Name = "Logo TEMPO.png"; Env = "METRONOME_LOGO"; Default = "\\192.168.10.100\02 - affaires\02.2 - SYNTHESE\ZZ - METRONOME\Content\Logo TEMPO.png" },
        @{ Name = "Rythme.png"; Env = "METRONOME_LOGO_RYTHME"; Default = "\\192.168.10.100\02 - affaires\02.2 - SYNTHESE\ZZ - METRONOME\Content\Rythme.png" },
        @{ Name = "T logo.png"; Env = "METRONOME_LOGO_TMARK"; Default = "\\192.168.10.100\02 - affaires\02.2 - SYNTHESE\ZZ - METRONOME\Content\T logo.png" },
        @{ Name = "QR CODE.png"; Env = "METRONOME_QR"; Default = "\\192.168.10.100\02 - affaires\02.2 - SYNTHESE\ZZ - METRONOME\Content\QR CODE.png" }
    )

    if (-not (Test-Path $effectiveAssetsDir)) {
        Write-Host "Dossier assets absent ($effectiveAssetsDir), tentative de reconstruction automatique..." -ForegroundColor Yellow
        $effectiveAssetsDir = Join-Path $scriptRoot ".build-assets"
        New-Item -Path $effectiveAssetsDir -ItemType Directory -Force | Out-Null

        $missing = @()
        foreach ($logo in $requiredLogos) {
            $name = $logo.Name
            $source = Resolve-LogoSource -FileName $name -EnvVarName $logo.Env -FallbackCandidates @(
                (Join-Path $scriptRoot $name),
                (Join-Path (Get-Location).Path $name),
                (Join-Path $scriptRoot "assets\$name"),
                (Join-Path $TempoCrAssetsDir $name),
                $logo.Default
            )

            if (-not $source) {
                $missing += "$name (env: $($logo.Env))"
                continue
            }

            Copy-Item -Path $source -Destination (Join-Path $effectiveAssetsDir $name) -Force
        }

        if ($missing.Count -gt 0) {
            throw "Impossible de retrouver certains logos:`n - $($missing -join "`n - ")`nCréez un dossier assets/ ou définissez les variables d'environnement indiquées."
        }
    }

    $missingInAssets = @()
    foreach ($logo in $requiredLogos) {
        $path = Join-Path $effectiveAssetsDir $logo.Name
        if (-not (Test-Path $path)) {
            $missingInAssets += $path
        }
    }
    if ($missingInAssets.Count -gt 0) {
        throw "Logos manquants dans $effectiveAssetsDir:`n - $($missingInAssets -join "`n - ")"
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

    foreach ($logo in $requiredLogos) {
        Add-DataArg -Args $args -Source (Join-Path $effectiveAssetsDir $logo.Name) -Dest "assets"
    }

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
