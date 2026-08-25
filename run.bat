@echo off
setlocal
set CMD=%1

if "%CMD%"=="" goto usage

if "%CMD%"=="install" (
    call scripts\install.bat
    goto :eof
)
if "%CMD%"=="dev" (
    call scripts\dev.bat
    goto :eof
)
if "%CMD%"=="publish" (
    echo [1/3] Memperbarui TOC dan Membangun Buku...
    call scripts\publish.bat
    
    echo.
    echo [2/3] Menyiapkan File untuk GitHub...
    git add .
    
    echo [3/3] Mengunggah Perubahan...
    :: Menggunakan timestamp agar pesan commit selalu unik
    git commit -m "Update konten PSD: %date% %time%"
    git push origin main
    
    echo.
    echo ==========================================
    echo BERHASIL! Buku sudah terbit di GitHub.
    echo ==========================================
    goto :eof
)
if "%CMD%"=="config" (
    call scripts\setup.bat
    goto :eof
)
if "%CMD%"=="reset" (
    echo Resetting project...
    if exist __pycache__ rmdir /S /Q __pycache__
    if exist _build rmdir /S /Q _build
    if exist docs rmdir /S /Q docs
    if exist .env del .env
    if exist scripts\dev.log del scripts\dev.log
    if exist scripts\dev_server.log del scripts\dev_server.log
    if exist venv rmdir /S /Q venv
    if exist Pendat rmdir /S /Q Pendat
    echo Done. All build artifacts and virtual environment removed.
    goto :eof
)

:usage
echo ==========================================
echo          Jupyter-OPZ Master Tool
echo ==========================================
echo Usage: .\run.bat [command]
echo.
echo Commands:
echo   install   : Setup environment and build book
echo   dev       : Start dev server ^& Markdown Canvas
echo   publish   : Update TOC and build to /docs
echo   config    : Update Author identity ^& GitHub Repo
echo   reset     : Full cleanup (removes venv, build, etc)
echo ==========================================
pause
goto :eof
