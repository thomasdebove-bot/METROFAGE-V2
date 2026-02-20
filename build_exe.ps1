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

function Normalize-FileName {
    param([string]$Name)

    if (-not $Name) { return "" }

    $base = [System.IO.Path]::GetFileName($Name).ToLowerInvariant()
    $normalized = $base.Normalize([Text.NormalizationForm]::FormD)
    $builder = New-Object System.Text.StringBuilder
    foreach ($ch in $normalized.ToCharArray()) {
        $cat = [Globalization.CharUnicodeInfo]::GetUnicodeCategory($ch)
        if ($cat -ne [Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$builder.Append($ch)
        }
    }
    return ($builder.ToString() -replace '\s+', ' ').Trim()
}

function Find-LogoInDirectory {
    param(
        [string]$Directory,
        [string[]]$Aliases
    )

    if (-not (Test-Path $Directory)) {
        return $null
    }

    $targetSet = @{}
    foreach ($alias in $Aliases) {
        $targetSet[(Normalize-FileName $alias)] = $true
    }

    $files = Get-ChildItem -Path $Directory -File -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        $norm = Normalize-FileName $f.Name
        if ($targetSet.ContainsKey($norm)) {
            return $f.FullName
        }
    }

    return $null
}

try {
    if (-not (Test-Path $EntryPoint)) {
        throw "Python entrypoint not found: $EntryPoint"
    }

    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    if (-not $scriptRoot) { $scriptRoot = (Get-Location).Path }

    $effectiveAssetsDir = $AssetsDir
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
        @{ Canonical = "Logo EIFFAGE.png"; Env = "METRONOME_LOGO_EIFFAGE"; Aliases = @("Logo EIFFAGE.png") },
        @{ Canonical = "Carre eiffage.png"; Env = "METRONOME_LOGO_EIFFAGE_SQUARE"; Aliases = @("Carre eiffage.png", "Carré eiffage.png", "CarrÃ© eiffage.png") },
        @{ Canonical = "Carre eiffage 90.png"; Env = "METRONOME_LOGO_EIFFAGE_SQUARE_90"; Aliases = @("Carre eiffage 90.png", "Carré eiffage 90.png", "CarrÃ© eiffage 90.png") },
        @{ Canonical = "Logo TEMPO.png"; Env = "METRONOME_LOGO"; Aliases = @("Logo TEMPO.png") },
        @{ Canonical = "Rythme.png"; Env = "METRONOME_LOGO_RYTHME"; Aliases = @("Rythme.png") },
        @{ Canonical = "T logo.png"; Env = "METRONOME_LOGO_TMARK"; Aliases = @("T logo.png") },
        @{ Canonical = "QR CODE.png"; Env = "METRONOME_QR"; Aliases = @("QR CODE.png") }
    )

    # Always stage assets with canonical names to avoid encoding issues on Windows PowerShell.
    $stagingDir = Join-Path $scriptRoot ".build-assets"
    New-Item -Path $stagingDir -ItemType Directory -Force | Out-Null

    $missing = @()
    foreach ($logo in $requiredLogos) {
        $canonical = $logo.Canonical
        $aliases = $logo.Aliases

        $source = Resolve-LogoSource -EnvVarName $logo.Env -FallbackCandidates @(
            (Find-LogoInDirectory -Directory $effectiveAssetsDir -Aliases $aliases),
            (Find-LogoInDirectory -Directory $TempoCrAssetsDir -Aliases $aliases),
            (Find-LogoInDirectory -Directory (Join-Path $scriptRoot "assets") -Aliases $aliases),
            (Find-LogoInDirectory -Directory $scriptRoot -Aliases $aliases)
        )

        if (-not $source) {
            $missing += "$canonical (env: $($logo.Env))"
            continue
        }

        Copy-Item -Path $source -Destination (Join-Path $stagingDir $canonical) -Force
    }

    if ($missing.Count -gt 0) {
        throw "Missing logos:`n - $($missing -join "`n - ")`nUse -AssetsDir 'C:\tempo-cr\assets' or set METRONOME_LOGO_* env vars."
    }

    Write-Host "[1/3] Installing build dependencies..."
    & $Python -m pip install --upgrade pip pyinstaller | Out-Host

    Write-Host "[2/3] Building executable..."
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
        Add-DataArg -Args $args -Source (Join-Path $stagingDir $logo.Canonical) -Dest "assets"
    }

    $args.Add($EntryPoint)
    & $Python @args | Out-Host

    Write-Host "[3/3] Build complete. Executable: dist/$ExeName.exe"
    Write-Host "Run dist/$ExeName.exe (server starts on http://127.0.0.1:8090)."
}
catch {
    Write-Host "Build error:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "\nPress Enter to close..."
    [void](Read-Host)
    exit 1
}
