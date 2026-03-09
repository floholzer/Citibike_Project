@echo off
echo ============================================
echo   Citi Bike ELT Pipeline starten
echo ============================================
echo.

cd /d "%~dp0"

echo [1/3] Starte Docker-Container...
docker-compose up -d
if %ERRORLEVEL% neq 0 (
    echo FEHLER: Docker-Container konnten nicht gestartet werden.
    pause
    exit /b 1
)

echo.
echo [2/3] Python-Umgebung vorbereiten...
if not exist ".venv" (
    echo   Erstelle virtuelle Umgebung...
    python -m venv .venv
    if %ERRORLEVEL% neq 0 (
        echo FEHLER: venv konnte nicht erstellt werden.
        pause
        exit /b 1
    )
)
call .venv\Scripts\activate
pip install -r requirements.txt --quiet
if %ERRORLEVEL% neq 0 (
    echo FEHLER: Pakete konnten nicht installiert werden.
    pause
    exit /b 1
)

echo.
echo [3/3] Starte Pipeline...
python run_pipeline.py
if %ERRORLEVEL% neq 0 (
    echo FEHLER: Pipeline abgebrochen.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   Pipeline erfolgreich abgeschlossen!
echo ============================================
pause
