param(
    [ValidateSet('check','package')]
    [string]$Mode = 'check',
    [string]$Python = 'python',
    [string]$OutDir = 'dist'
)

$ErrorActionPreference = 'Stop'

function Invoke-Step {
    param(
        [string]$Label,
        [scriptblock]$Action
    )
    Write-Host "`n==> $Label" -ForegroundColor Cyan
    & $Action
}

Invoke-Step "Validation de l'environnement Python" {
    & $Python --version
}

Invoke-Step "Compilation de contrôle" {
    & $Python -m py_compile app.py
}

if ($Mode -eq 'package') {
    Invoke-Step "Installation de PyInstaller (si nécessaire)" {
        & $Python -m pip install --upgrade pip pyinstaller
    }

    Invoke-Step "Build binaire" {
        & $Python -m PyInstaller \
            --noconfirm \
            --clean \
            --onefile \
            --name metrofage \
            --distpath $OutDir \
            app.py
    }

    Write-Host "`nBuild terminé. Binaire disponible dans: $OutDir" -ForegroundColor Green
}
else {
    Write-Host "`nMode check terminé (aucun binaire généré)." -ForegroundColor Green
}
