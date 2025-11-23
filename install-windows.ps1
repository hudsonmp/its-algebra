# Windows Installation Script for its-algebra Project
# Run this script in PowerShell as Administrator: 
# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# .\install-windows.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "its-algebra Project Setup for Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as Administrator. Some installations may require admin rights." -ForegroundColor Yellow
    Write-Host ""
}

# Function to check if a command exists
function Test-Command {
    param($command)
    $null = Get-Command $command -ErrorAction SilentlyContinue
    return $?
}

# 1. Check/Install Docker Desktop
Write-Host "[1/4] Checking Docker Desktop..." -ForegroundColor Green
if (Test-Command docker) {
    $dockerVersion = docker --version
    Write-Host "✓ Docker found: $dockerVersion" -ForegroundColor Green
} else {
    Write-Host "✗ Docker not found. Please install Docker Desktop for Windows:" -ForegroundColor Red
    Write-Host "  Download from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    Write-Host "  After installation, restart your computer and run this script again." -ForegroundColor Yellow
    Write-Host ""
    $installDocker = Read-Host "Press Enter to open Docker Desktop download page (or 'skip' to continue)"
    if ($installDocker -ne "skip") {
        Start-Process "https://www.docker.com/products/docker-desktop/"
    }
    Write-Host ""
}

# 2. Check/Install Python
Write-Host "[2/4] Checking Python..." -ForegroundColor Green
if (Test-Command python) {
    $pythonVersion = python --version
    Write-Host "✓ Python found: $pythonVersion" -ForegroundColor Green
    
    # Check if pip is available
    if (Test-Command pip) {
        Write-Host "✓ pip found" -ForegroundColor Green
    } else {
        Write-Host "✗ pip not found. Installing pip..." -ForegroundColor Yellow
        python -m ensurepip --upgrade
    }
} else {
    Write-Host "✗ Python not found. Please install Python 3.8 or higher:" -ForegroundColor Red
    Write-Host "  Download from: https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "  Make sure to check 'Add Python to PATH' during installation!" -ForegroundColor Yellow
    Write-Host ""
    $installPython = Read-Host "Press Enter to open Python download page (or 'skip' to continue)"
    if ($installPython -ne "skip") {
        Start-Process "https://www.python.org/downloads/"
    }
    Write-Host ""
    Write-Host "After installing Python, restart PowerShell and run this script again." -ForegroundColor Yellow
    exit 1
}

# 3. Install Python dependencies
Write-Host "[3/4] Installing Python dependencies..." -ForegroundColor Green
if (Test-Command pip) {
    Write-Host "Installing pandas..." -ForegroundColor Yellow
    pip install pandas --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ pandas installed successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to install pandas. Try running: pip install pandas" -ForegroundColor Red
    }
} else {
    Write-Host "✗ pip not available. Cannot install Python dependencies." -ForegroundColor Red
}

# 4. Install Helix CLI
Write-Host "[4/4] Installing Helix CLI..." -ForegroundColor Green
if (Test-Command helix) {
    $helixVersion = helix --version 2>&1
    Write-Host "✓ Helix CLI found: $helixVersion" -ForegroundColor Green
} else {
    Write-Host "Installing Helix CLI..." -ForegroundColor Yellow
    
    # Try using cargo (Rust package manager) if available
    if (Test-Command cargo) {
        Write-Host "Installing via cargo..." -ForegroundColor Yellow
        cargo install helix-cli
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Helix CLI installed via cargo" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to install via cargo" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Helix CLI not found and cargo is not available." -ForegroundColor Red
        Write-Host "  Please install Rust and Cargo first:" -ForegroundColor Yellow
        Write-Host "  Download from: https://rustup.rs/" -ForegroundColor Yellow
        Write-Host "  Then run: cargo install helix-cli" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  OR install Helix CLI manually:" -ForegroundColor Yellow
        Write-Host "  Check: https://github.com/helix-editor/helix or https://docs.helix-editor.com/" -ForegroundColor Yellow
        Write-Host ""
        $installRust = Read-Host "Press Enter to open Rust installation page (or 'skip' to continue)"
        if ($installRust -ne "skip") {
            Start-Process "https://rustup.rs/"
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Make sure Docker Desktop is running" -ForegroundColor White
Write-Host "2. Navigate to the project directory" -ForegroundColor White
Write-Host "3. Run: helix dev" -ForegroundColor White
Write-Host ""
Write-Host "The project will be available at: http://localhost:6969" -ForegroundColor Green
Write-Host ""

