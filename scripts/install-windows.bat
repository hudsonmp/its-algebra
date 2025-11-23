@echo off
REM Windows Installation Script for its-algebra Project
REM Run this file by double-clicking it or running: install-windows.bat

echo ========================================
echo its-algebra Project Setup for Windows
echo ========================================
echo.

echo [1/4] Checking Docker Desktop...
docker --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Docker is installed
    docker --version
) else (
    echo [ERROR] Docker not found!
    echo Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/
    echo After installation, restart your computer and run this script again.
    pause
    start https://www.docker.com/products/docker-desktop/
    exit /b 1
)
echo.

echo [2/4] Checking Python...
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Python is installed
    python --version
) else (
    echo [ERROR] Python not found!
    echo Please install Python 3.8+ from: https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation!
    pause
    start https://www.python.org/downloads/
    exit /b 1
)
echo.

echo [3/4] Installing Python dependencies...
pip install pandas
if %errorlevel% equ 0 (
    echo [OK] pandas installed successfully
) else (
    echo [ERROR] Failed to install pandas
    echo Try running: pip install pandas
)
echo.

echo [4/4] Checking Helix CLI...
helix --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Helix CLI is installed
    helix --version
) else (
    echo [WARNING] Helix CLI not found!
    echo.
    echo To install Helix CLI:
    echo 1. Install Rust from: https://rustup.rs/
    echo 2. Run: cargo install helix-cli
    echo.
    echo OR check the Helix documentation for Windows installation:
    echo https://docs.helix-editor.com/
    pause
    start https://rustup.rs/
)
echo.

echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Make sure Docker Desktop is running
echo 2. Navigate to this project directory
echo 3. Run: helix dev
echo.
echo The project will be available at: http://localhost:6969
echo.
pause

