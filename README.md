# 🚴‍♂️ Citi Bike Data Warehouse: Setup- & Ausführungs-Guide

Willkommen im Data Engineering Projekt! Diese Anleitung führt dich Schritt für Schritt durch die Einrichtung unserer ELT-Pipeline, vom Starten der lokalen Datenbank bis zur Ausführung des Codes.

## 1. Voraussetzungen (Software)

Bitte stelle sicher, dass folgende Standard-Programme auf deinem Rechner installiert sind:

* **Python** (Version 3.8 oder neuer)
* **Docker Desktop** (Muss gestartet und im Hintergrund aktiv sein)
* **Visual Studio Code (VS Code)**
* **Power BI Desktop** (Für das spätere Dashboard)

## 2. VS Code Extensions installieren

Öffne das Projekt in VS Code. Gehe auf der linken Seite zu den "Extensions" (die vier Quadrate) und installiere folgende Erweiterungen:

* **Python** (von Microsoft)
* **Jupyter** (von Microsoft) – *Für unsere Prototyp-Notebooks*
* **Docker** (von Microsoft) – *Für das Datenbank-Management*
* **SQLTools** (von Matheus) – *Unser Datenbank-Client*
* **SQLTools PostgreSQL/Cockroach Driver** (von Matheus) – *Der Treiber für unsere DB*

## 3. Die Datenbank starten (Docker)

Wir nutzen eine PostgreSQL-Datenbank, die sauber gekapselt in einem Docker-Container läuft.

1. Öffne ein neues Terminal in VS Code (`Terminal -> New Terminal`).
2. Stelle sicher, dass du dich im Hauptordner des Projekts befindest (dort, wo die `docker-compose.yml` liegt).
3. Führe folgenden Befehl aus:
`docker-compose up -d`
4. *Info: Docker lädt nun PostgreSQL herunter und startet die leere Datenbank `citibike_dwh` auf Port 5432. Das `-d` sorgt dafür, dass sie ungestört im Hintergrund läuft.*

## 4. Python-Umgebung einrichten

Damit unser Python-Skript die Daten laden und transformieren kann, brauchen wir einige Bibliotheken. Wir nutzen dafür eine **virtuelle Umgebung (venv)**, damit die Pakete sauber vom Rest des Systems getrennt sind.

1. Gehe wieder in das VS Code Terminal.
2. Erstelle eine virtuelle Umgebung im Projektordner:
   ```bash
   python -m venv .venv
   ```
3. Aktiviere die Umgebung:
   * **Windows:**
     ```bash
     .venv\Scripts\activate
     ```
   * **Mac / Linux:**
     ```bash
     source .venv/bin/activate
     ```
   *(Du erkennst eine aktive venv daran, dass `(.venv)` am Anfang der Terminalzeile erscheint.)*
4. Installiere alle benötigten Pakete:
   ```bash
   pip install -r requirements.txt
   ```

> **Hinweis:** Die venv muss jedes Mal aktiviert werden, wenn du ein neues Terminal öffnest. VS Code erkennt sie meist automatisch und aktiviert sie selbstständig.

## 5. Datenbank-Verbindung in VS Code (SQLTools)

Damit wir uns die Tabellen in VS Code ansehen können, richten wir die Verbindung ein:

1. Klicke in der linken Seitenleiste auf das **SQLTools-Symbol** (die kleine Datenbank-Tonne).
2. Klicke auf **"Add new connection"** und wähle **PostgreSQL**.
3. Trage folgende Daten exakt so ein:
* **Connection name:** Citibike DWH
* **Server Address:** `localhost`
* **Port:** `5432`
* **Database:** `citibike_dwh`
* **Username:** `admin`
* **Password:** `password123`


4. Klicke unten auf **"Save Connection"** und danach auf **"Connect Now"**. Du siehst die Datenbank nun links im Menü.

## 6. Datenbank-Verwaltung mit pgAdmin (Optional)

Als Alternative zu SQLTools kann auch **pgAdmin** genutzt werden – ein vollständiges, browserbasiertes GUI für PostgreSQL. Es ist bereits im Docker-Stack integriert und läuft automatisch mit.

1. Stelle sicher, dass die Docker-Container laufen (`docker-compose up -d`).
2. Öffne im Browser: [http://localhost:5050](http://localhost:5050)
3. Melde dich mit folgenden Daten an:
   * **E-Mail:** `admin@citibike.com`
   * **Passwort:** `admin`
4. Klicke links auf **"Add New Server"** und trage ein:
   * **Name:** `Citibike DWH` (frei wählbar)
   * Unter dem Reiter **Connection:**
     * **Host:** `postgres` *(nicht `localhost` – Docker-interner Name)*
     * **Port:** `5432`
     * **Database:** `citibike_dwh`
     * **Username:** `admin`
     * **Password:** `password123`
5. Klicke auf **Save**. Du siehst die Datenbank nun im linken Baum.

> **Tipp:** pgAdmin eignet sich besonders gut für komplexere SQL-Abfragen, das Durchsuchen von Tabellen und die visuelle Darstellung des Schemas.

## 7. Die Automatisierte Pipeline starten

Unser Projekt ist vollständig automatisiert. Du musst keine einzelnen Skripte händisch ausführen. Das Start-Script sorgt dafür, dass Docker läuft und die Pipeline angestoßen wird.

Das Script (`run_pipeline.py`) übernimmt dabei folgende Schritte:
* Es lädt die Citi Bike CSV-Dateien (Jahre 2022-2025) herunter.
* Es zieht die historischen Wetterdaten über die Open-Meteo API.
* Es pusht die Daten in unsere lokale PostgreSQL-Datenbank.
* Es triggert unsere SQL-Skripte aus dem Ordner `sql_transformations`, um das Star Schema aufzubauen.

### Windows

1. Gehe in den Windows-Explorer (in deinen Projektordner).
2. Mache einen **Doppelklick** auf die Datei **`start_pipeline.bat`**.
3. Das schwarze Terminalfenster öffnet sich und führt die Pipeline aus.

### Mac / Linux

1. Öffne ein Terminal und wechsle in den Projektordner.
2. Mache das Script beim ersten Mal ausführbar (einmalig nötig):
   ```bash
   chmod +x start_pipeline.sh
   ```
3. Starte die Pipeline:
   ```bash
   ./start_pipeline.sh
   ```



## 8. Daten in Power BI laden (Das Star Schema)

Sobald die Pipeline erfolgreich durchgelaufen ist, können wir die Daten visualisieren.

1. Öffne **Power BI Desktop**.
2. Klicke auf **Daten abrufen** -> **Mehr...** -> **PostgreSQL-Datenbank**.
3. Gib ein: Server: `localhost`, Datenbank: `citibike_dwh`, Modus: **Importieren**.
4. Gehe links auf den Reiter **Datenbank** und nutze die Zugangsdaten (`admin` / `password123`).
5. Wähle im Navigator die **`fact_trips`** Tabelle sowie alle vier **`dim_`** Tabellen aus und lade sie.
6. Gehe links in die **Modellansicht**, um unser fertiges Star Schema zu bewundern!

