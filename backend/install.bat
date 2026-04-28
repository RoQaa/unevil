@echo off
echo ==========================================
echo  Unveil Backend - Dependencies Installer
echo ==========================================
echo.
echo Installing Python libraries from requirements.txt...
pip install -r requirements.txt

echo.
echo Checking for FFmpeg (Required for audio processing)...
where ffmpeg >nul 2>nul
if %errorlevel% == 0 (
    echo [OK] FFmpeg is installed.
) else (
    echo [WARNING] FFmpeg is NOT installed or not in PATH!
    echo Please install FFmpeg from https://ffmpeg.org/download.html
    echo or using Winget: winget install ffmpeg
)

echo.
echo Installation complete!
pause
