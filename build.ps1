param(
    [ValidateSet('check','package')]
    [string]$Mode = 'check',
    [string]$Python = 'python',
    [string]$OutDir = 'dist',
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
    if ($LogFile) {
        Start-Transcript -Path $LogFile -Append | Out-Null
    }

    Invoke-Step "Validation de l'environnement Python" {
        Invoke-Cmd -File $Python -Arguments @('--version')
    }

    Invoke-Step "Compilation de contrôle" {
        Invoke-Cmd -File $Python -Arguments @('-m', 'py_compile', 'app.py')
    }

    if ($Mode -eq 'package') {
        Invoke-Step "Installation de PyInstaller (si nécessaire)" {
            Invoke-Cmd -File $Python -Arguments @('-m', 'pip', 'install', '--upgrade', 'pip', 'pyinstaller')
        }

        Invoke-Step "Build binaire" {
            Invoke-Cmd -File $Python -Arguments @(
                '-m', 'PyInstaller',
                '--noconfirm',
                '--clean',
                '--onefile',
                '--name', 'metrofage',
                '--distpath', $OutDir,
                'app.py'
            )
        }

        Write-Host "`nBuild terminé. Binaire disponible dans: $OutDir" -ForegroundColor Green
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
    if ($PauseOnExit) {
        Read-Host "Appuie sur Entrée pour fermer"
    }
}
