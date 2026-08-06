#!/bin/bash
echo "[Traccar Local] Verificando Java..."
if ! command -v java &> /dev/null; then
    echo "ERROR: Java no está instalado"
    exit 1
fi
echo "[Traccar Local] Iniciando Traccar en puerto 8082..."
echo "[Traccar Local] Dashboard disponible en: http://localhost:8082"
echo "[Traccar Local] Presiona Ctrl+C para detener el servidor"
java -jar target/tracker-server.jar
