param(
    [ValidateSet('package','check')]
    [string]$Mode = 'package',
    [string]$Python = 'python',
    [string]$OutDir = '',
    [string]$LogFile = 'build.log',
    [switch]$PauseOnExit
)

$ErrorActionPreference = 'Stop'

function Invoke-Cmd {
    param(
        [Parameter(Mandatory = $true)]
        [string]$File,
        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @()
    )

    & $File @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Commande en échec: $File $($Arguments -join ' ')"
    }
}

function Invoke-Step {
    param(
        [string]$Label,
        [scriptblock]$Action
    )
    Write-Host "`n==> $Label" -ForegroundColor Cyan
    & $Action
}

try {
    if (-not $PSScriptRoot) {
        $PSScriptRoot = (Get-Location).Path
    }

    Push-Location $PSScriptRoot

    if ([string]::IsNullOrWhiteSpace($OutDir)) {
        $OutDir = Join-Path $PSScriptRoot 'dist'
    }

    $appPath = Join-Path $PSScriptRoot 'app.py'
    if (-not (Test-Path -LiteralPath $appPath)) {
        throw "app.py introuvable dans: $PSScriptRoot"
    }

    if ($LogFile) {
        $logPath = if ([System.IO.Path]::IsPathRooted($LogFile)) { $LogFile } else { Join-Path $PSScriptRoot $LogFile }
        Start-Transcript -Path $logPath -Append | Out-Null
        $LogFile = $logPath
    }

    Write-Host "Mode sélectionné: $Mode" -ForegroundColor DarkCyan
    Write-Host "Répertoire du script: $PSScriptRoot" -ForegroundColor DarkCyan
    Write-Host "Sortie binaire: $OutDir" -ForegroundColor DarkCyan

    Invoke-Step "Validation de l'environnement Python" {
        Invoke-Cmd -File $Python -Arguments @('--version')
    }

    Invoke-Step "Compilation de contrôle" {
        Invoke-Cmd -File $Python -Arguments @('-m', 'py_compile', $appPath)
    }

    if ($Mode -eq 'package') {
        Invoke-Step "Installation de PyInstaller (si nécessaire)" {
            Invoke-Cmd -File $Python -Arguments @('-m', 'pip', 'install', '--upgrade', 'pip', 'pyinstaller')
        }

        Invoke-Step "Build binaire" {
            $logoEiffage = 'C:\tempo-cr\Logo EIFFAGE.png'
            $logoSquare = 'C:\tempo-cr\Carré eiffage.png'
            $logoSquare90 = 'C:\tempo-cr\Carré eiffage 90.png'

            $pyInstallerArgs = @(
                '-m', 'PyInstaller',
                '--noconfirm',
                '--clean',
                '--onefile',
                '--name', 'metrofage',
                '--distpath', $OutDir,
                '--add-data', "$logoEiffage;.",
                '--add-data', "$logoSquare;.",
                '--add-data', "$logoSquare90;.",
                $appPath
            )

            Invoke-Cmd -File $Python -Arguments $pyInstallerArgs
        }

        $exePath = Join-Path $OutDir 'metrofage.exe'
        if (-not (Test-Path -LiteralPath $exePath)) {
            throw "Build terminé mais EXE introuvable: $exePath"
        }

        Write-Host "`nBuild terminé. Binaire disponible: $exePath" -ForegroundColor Green
    }
    else {
        Write-Host "`nMode check terminé (aucun binaire généré)." -ForegroundColor Green
    }
}
catch {
    Write-Host "`nERREUR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Consulte le log: $LogFile" -ForegroundColor Yellow
    exit 1
}
finally {
    try { Stop-Transcript | Out-Null } catch { }
    try { Pop-Location } catch { }
    if ($PauseOnExit) {
        Read-Host "Appuie sur Entrée pour fermer"
    }
}
