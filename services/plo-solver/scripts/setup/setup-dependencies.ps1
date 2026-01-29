#requires -Version 5.1
<#
    PLOSolver Windows dependency setup (PowerShell)

    What this script does:
    - Ensures WSL2 with Ubuntu 22.04 is installed
    - Ensures Docker Desktop is installed (so local infra runs in containers)
    - Installs essential build tools + Python 3.11 + Node.js LTS inside WSL
    - Runs make targets inside WSL to install Python/Node dependencies

    Usage (run from repo root in an elevated PowerShell):
      powershell -ExecutionPolicy Bypass -File .\scripts\setup\setup-dependencies.ps1

    After completion:
      wsl -d Ubuntu-22.04 -- bash -lc "cd <repo_path_in_wsl> && make run-local"

    Notes:
    - This script favors WSL2 (recommended) over native Windows installs
    - It assumes Docker Desktop is used with WSL integration enabled
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info([string]$Message)  { Write-Host "[INFO]  $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message)    { Write-Host "[OK]    $Message" -ForegroundColor Green }
function Write-Warn([string]$Message)  { Write-Host "[WARN]  $Message" -ForegroundColor Yellow }
function Write-Fail([string]$Message)  { Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Test-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-RepoRoot {
    param([string]$Path)
    $packageJson = Join-Path $Path 'src/frontend/package.json'
    $backendDir = Join-Path $Path 'src/backend'
    if (-not (Test-Path $packageJson) -or -not (Test-Path $backendDir)) {
        Write-Fail "Run this from the PLOSolver repository root. Expected to find 'src/frontend/package.json' and 'src/backend/'. Current: $Path"
        exit 1
    }
}

function Ensure-Winget {
    if (Get-Command winget -ErrorAction SilentlyContinue) { return $true }
    Write-Warn "'winget' not found. Please install winget (App Installer) from Microsoft Store and re-run."
    return $false
}

function Ensure-DockerDesktop {
    if (-not (Ensure-Winget)) { return $false }
    try {
        $list = winget list --id Docker.DockerDesktop --accept-source-agreements 2>$null
        if ($LASTEXITCODE -eq 0 -and ($list -match 'Docker Desktop')) {
            Write-Ok "Docker Desktop already installed"
            return $true
        }
    } catch { }

    Write-Info "Installing Docker Desktop via winget..."
    winget install --id Docker.DockerDesktop --silent --accept-package-agreements --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Docker Desktop install may have failed or requires a reboot. Please ensure Docker Desktop is installed and WSL integration is enabled."
        return $false
    }
    Write-Ok "Docker Desktop installed"
    return $true
}

function Ensure-WSLAndDistro {
    param(
        [string]$DistroName = 'Ubuntu-22.04'
    )

    if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
        Write-Fail "WSL is not available on this system. Requires Windows 10 (2004+) or Windows 11."
        exit 1
    }

    $needReboot = $false
    $isAdmin = Test-Admin

    # Ensure WSL optional features are enabled
    try {
        $featureWsl = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux)
        $featureVm  = (Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform)
        if ($featureWsl.State -ne 'Enabled' -or $featureVm.State -ne 'Enabled') {
            if (-not $isAdmin) {
                Write-Fail "Enabling WSL features requires Administrator. Re-run PowerShell as Administrator."
                exit 1
            }
            Write-Info "Enabling WSL and Virtual Machine Platform features..."
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart | Out-Null
            Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart | Out-Null
            $needReboot = $true
        }
    } catch {
        Write-Warn "Could not verify/enable WSL features automatically. If WSL is not installed, run: 'wsl --install' and reboot."
    }

    # Default to WSL2
    try { wsl --set-default-version 2 | Out-Null } catch { }

    # Check if requested distro exists
    $distros = & wsl -l -q 2>$null | Where-Object { $_ -match '\S' } | ForEach-Object { $_.Trim() }
    if (-not ($distros -contains $DistroName)) {
        if (-not $isAdmin) {
            Write-Fail "Installing $DistroName requires Administrator. Re-run PowerShell as Administrator."
            exit 1
        }
        Write-Info "Installing $DistroName... (this may take several minutes)"
        & wsl --install -d $DistroName | Out-Null
        $needReboot = $true
    }

    if ($needReboot) {
        Write-Warn "A reboot is required to complete WSL/Docker installation. Please reboot, then re-run this script."
        exit 0
    }

    Write-Ok "$DistroName is available"
}

function Convert-ToWslPath {
    param([string]$WindowsPath)
    if ($WindowsPath -match '^[A-Za-z]:\\') {
        $drive = ($WindowsPath.Substring(0,1)).ToLower()
        $rest = $WindowsPath.Substring(2).Replace('\\','/')
        return "/mnt/$drive$rest"
    }
    # Already looks like a WSL path or UNC; return as-is
    return $WindowsPath
}

function Invoke-InWSL {
    param(
        [string]$DistroName,
        [string]$Command
    )
    Write-Info "[WSL:$DistroName] $Command"
    & wsl -d $DistroName -- bash -lc "$Command"
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed in WSL: $Command"
    }
}

# Entry
Write-Host "PLOSolver Windows Dependency Setup" -ForegroundColor Magenta
Write-Host "==================================" -ForegroundColor Magenta

$repoRoot = (Get-Item -Path (Resolve-Path '.')).FullName
Assert-RepoRoot -Path $repoRoot

# Ensure Docker Desktop (best-effort, user can also install manually)
Ensure-DockerDesktop | Out-Null

$distro = 'Ubuntu-22.04'
Ensure-WSLAndDistro -DistroName $distro

# Map repo path to WSL path
$repoWslPath = Convert-ToWslPath -WindowsPath $repoRoot
Write-Info "Repo (Windows): $repoRoot"
Write-Info "Repo (WSL):     $repoWslPath"

# Prepare base dependencies inside WSL
Invoke-InWSL -DistroName $distro -Command 'sudo apt-get update -y'
Invoke-InWSL -DistroName $distro -Command 'sudo apt-get install -y make curl ca-certificates gnupg build-essential libpq-dev'

# Install Python 3.11 if not present
Invoke-InWSL -DistroName $distro -Command 'if ! command -v python3.11 >/dev/null 2>&1; then sudo apt-get install -y python3.11 python3.11-venv python3-pip; fi'

# Install Node.js LTS (18.x) if not present
Invoke-InWSL -DistroName $distro -Command 'if ! command -v node >/dev/null 2>&1; then curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && sudo apt-get install -y nodejs; fi'

# Install project dependencies via Makefile inside WSL (Python + Node)
Invoke-InWSL -DistroName $distro -Command "cd $repoWslPath && make deps-python"
Invoke-InWSL -DistroName $distro -Command "cd $repoWslPath && make deps-node"

# Verify tooling versions
Invoke-InWSL -DistroName $distro -Command 'python3 --version || true'
Invoke-InWSL -DistroName $distro -Command 'python3.11 --version || true'
Invoke-InWSL -DistroName $distro -Command 'node --version'
Invoke-InWSL -DistroName $distro -Command 'npm --version'

Write-Ok "Dependencies installed successfully inside WSL!"
Write-Host "" 
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1) Open Docker Desktop and enable WSL integration for $distro (Settings > Resources > WSL Integration)." -ForegroundColor Cyan
Write-Host "  2) Start the app from WSL:" -ForegroundColor Cyan
Write-Host "       wsl -d $distro -- bash -lc \"cd $repoWslPath && make run-local\"" -ForegroundColor White
Write-Host "  3) To run tests:" -ForegroundColor Cyan
Write-Host "       wsl -d $distro -- bash -lc \"cd $repoWslPath && make test-unit\"" -ForegroundColor White

Write-Ok "All set!"


