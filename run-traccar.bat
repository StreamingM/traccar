@echo off
REM Script para ejecutar Traccar localmente en Windows
echo [Traccar Local] Verificando Java...
java -version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Java no está instalado o no está en el PATH
    pause
    exit /b 1
)
echo [Traccar Local] Iniciando Traccar en puerto 8082...
echo [Traccar Local] Dashboard disponible en: http://localhost:8082
echo [Traccar Local] Presiona Ctrl+C para detener el servidor
echo.
java -jar target/tracker-server.jar
pause
