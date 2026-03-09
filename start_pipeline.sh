#!/bin/bash
echo "============================================"
echo "  Citi Bike ELT Pipeline starten"
echo "============================================"
echo

cd "$(dirname "$0")"

echo "[1/3] Starte Docker-Container..."
docker-compose up -d
if [ $? -ne 0 ]; then
    echo "FEHLER: Docker-Container konnten nicht gestartet werden."
    exit 1
fi

echo
echo "[2/3] Python-Umgebung vorbereiten..."
if [ ! -d ".venv" ]; then
    echo "  Erstelle virtuelle Umgebung..."
    python3 -m venv .venv
    if [ $? -ne 0 ]; then
        echo "FEHLER: venv konnte nicht erstellt werden."
        exit 1
    fi
fi
source .venv/bin/activate
pip install -r requirements.txt --quiet
if [ $? -ne 0 ]; then
    echo "FEHLER: Pakete konnten nicht installiert werden."
    exit 1
fi

echo
echo "[3/3] Starte Pipeline..."
python3 run_pipeline.py
if [ $? -ne 0 ]; then
    echo "FEHLER: Pipeline abgebrochen."
    exit 1
fi

echo
echo "============================================"
echo "  Pipeline erfolgreich abgeschlossen!"
echo "============================================"
