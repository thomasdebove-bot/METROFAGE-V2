param(
    [ValidateSet('package','check')]
    [string]$Mode = 'package',
    [string]$Python = 'python',
    [string]$OutDir = '',
    [string]$LogFile = 'build.log',
    [string]$LogoEiffagePath = 'C:\tempo-cr\Logo EIFFAGE.png',
    [string]$LogoSquarePath = 'C:\tempo-cr\Carré eiffage.png',
    [string]$LogoSquare90Path = 'C:\tempo-cr\Carré eiffage 90.png',
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

    $displayArgs = ($Arguments | ForEach-Object { '"{0}"' -f $_ }) -join ' '
    Write-Host "[cmd] $File $displayArgs" -ForegroundColor DarkGray

    & $File @Arguments
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Commande en échec (code $exitCode): $File $($Arguments -join ' ')"
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

function Assert-FileExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Label introuvable: $Path"
    }
}

try {
    if (-not $PSScriptRoot) {
        $PSScriptRoot = (Get-Location).Path
    }

    Push-Location $PSScriptRoot

    if ([string]::IsNullOrWhiteSpace($OutDir)) {
        $OutDir = Join-Path $PSScriptRoot 'dist'
    }

    if (-not ([System.IO.Path]::IsPathRooted($OutDir))) {
        $OutDir = Join-Path $PSScriptRoot $OutDir
    }

    $appPath = Join-Path $PSScriptRoot 'app.py'
    Assert-FileExists -Path $appPath -Label 'app.py'

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
        Invoke-Step "Validation des logos à embarquer" {
            Assert-FileExists -Path $LogoEiffagePath -Label 'Logo EIFFAGE'
            Assert-FileExists -Path $LogoSquarePath -Label 'Carré eiffage'
            Assert-FileExists -Path $LogoSquare90Path -Label 'Carré eiffage 90'
        }

        Invoke-Step "Installation de PyInstaller (si nécessaire)" {
            Invoke-Cmd -File $Python -Arguments @('-m', 'pip', 'install', '--upgrade', 'pip', 'pyinstaller')
        }

        Invoke-Step "Build binaire" {
            New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

            $pyInstallerArgs = @(
                '-m', 'pyinstaller',
                '--noconfirm',
                '--clean',
                '--onefile',
                '--name', 'metrofage',
                '--distpath', $OutDir,
                "--add-data=$LogoEiffagePath;.",
                "--add-data=$LogoSquarePath;.",
                "--add-data=$LogoSquare90Path;.",
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
