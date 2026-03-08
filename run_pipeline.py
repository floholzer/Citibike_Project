import time
import requests
import pandas as pd
from zipfile import ZipFile
from io import BytesIO
from sqlalchemy import create_engine, text

TIMEOUT = 60        # Sekunden bis ein HTTP-Request abbricht
MAX_RETRIES = 3     # Wie oft wir bei Netzwerkfehlern erneut versuchen
RETRY_DELAY = 5     # Sekunden Wartezeit zwischen Versuchen


def fetch_with_retry(url, retries=MAX_RETRIES, timeout=TIMEOUT):
    """HTTP GET mit Timeout und automatischem Retry bei Netzwerkfehlern."""
    for attempt in range(1, retries + 1):
        try:
            response = requests.get(url, timeout=timeout)
            return response
        except requests.exceptions.RequestException as e:
            print(f"   [Versuch {attempt}/{retries}] Netzwerkfehler: {e}")
            if attempt < retries:
                time.sleep(RETRY_DELAY)
    raise RuntimeError(f"Download fehlgeschlagen nach {retries} Versuchen: {url}")


def extract_table_name(dateiname):
    """Leitet den Tabellennamen aus dem Dateinamen ab, z.B. '01_create_dim_station.sql' -> 'dim_station'."""
    # Format: NN_create_<tabellenname>.sql
    stem = dateiname.replace('.sql', '')           # '01_create_dim_station'
    parts = stem.split('_create_', maxsplit=1)     # ['01', 'dim_station']
    if len(parts) != 2:
        raise ValueError(f"Unerwartetes Dateinamen-Format: {dateiname}")
    return parts[1]


# 1. Verbindung zur Datenbank
db_url = 'postgresql://admin:password123@localhost:5432/citibike_dwh'
engine = create_engine(db_url)

print("Starte ELT-Pipeline (Big Data Edition: 2022 - 2025)...")
print("-" * 50)

# ==========================================
# PHASE 1: Fahrräder (Extract & Load)
# ==========================================
print("1. Lade Citi Bike Daten...")

# Staging-Tabelle vorher leeren, damit wir keine Daten doppelt anhängen
with engine.begin() as conn:
    conn.execute(text("DROP TABLE IF EXISTS staging_citibike_trips;"))

fehlgeschlagene_monate = []

for year in range(2022, 2026):
    for month in range(1, 13):
        month_str = f"{month:02d}"
        url_bike = f"https://s3.amazonaws.com/tripdata/JC-{year}{month_str}-citibike-tripdata.csv.zip"

        print(f"   -> Lade Monat {month_str}/{year}...")
        try:
            response = fetch_with_retry(url_bike)

            if response.status_code == 200:
                zip_file = ZipFile(BytesIO(response.content))
                csv_filename = zip_file.namelist()[0]

                with zip_file.open(csv_filename) as f:
                    # Chunking schützt den Arbeitsspeicher bei Millionen von Zeilen
                    for chunk in pd.read_csv(f, chunksize=50000, low_memory=False):
                        chunk.to_sql('staging_citibike_trips', engine, if_exists='append', index=False)
            elif response.status_code == 404:
                print(f"   Datei für {month_str}/{year} nicht gefunden. Überspringe...")
            else:
                print(f"   Unerwarteter HTTP-Status {response.status_code} für {month_str}/{year}. Überspringe...")

        except Exception as e:
            print(f"   FEHLER bei {month_str}/{year}: {e}. Überspringe...")
            fehlgeschlagene_monate.append(f"{month_str}/{year}")

if fehlgeschlagene_monate:
    print(f"\n   Warnung: Folgende Monate konnten nicht geladen werden: {', '.join(fehlgeschlagene_monate)}")


# ==========================================
# PHASE 2: Wetter (Extract & Load)
# ==========================================
print("\n2. Lade historische Wetterdaten (2022 bis 2025)...")
url_weather = "https://archive-api.open-meteo.com/v1/archive?latitude=40.7143&longitude=-74.006&start_date=2022-01-01&end_date=2025-12-31&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=America%2FNew_York"

try:
    response_weather = fetch_with_retry(url_weather)
    response_weather.raise_for_status()
    data_weather = response_weather.json()

    weather_df = pd.DataFrame({
        'date_key': data_weather['daily']['time'],
        'temp_max_celsius': data_weather['daily']['temperature_2m_max'],
        'temp_min_celsius': data_weather['daily']['temperature_2m_min'],
        'precipitation_mm': data_weather['daily']['precipitation_sum']
    })
    weather_df.to_sql('staging_weather_historical', engine, if_exists='replace', index=False)
except Exception as e:
    raise RuntimeError(f"Phase 2 (Wetter) fehlgeschlagen: {e}") from e


# ==========================================
# PHASE 3: Transformation (Star Schema)
# ==========================================
print("\n3. Führe SQL-Transformationen aus...")

sql_dateien = [
    "01_create_dim_station.sql",
    "02_create_dim_date.sql",
    "03_create_dim_bike.sql",
    "04_create_fact_trips.sql",
    "05_create_dim_weather.sql"
]

with engine.begin() as conn:
    for datei in sql_dateien:
        print(f"   Führe {datei} aus...")
        pfad = f"sql_transformations/{datei}"

        try:
            with open(pfad, 'r', encoding='utf-8') as f:
                sql_befehl = f.read()
        except FileNotFoundError:
            raise FileNotFoundError(f"SQL-Datei nicht gefunden: {pfad}")

        tabellen_name = extract_table_name(datei)
        conn.execute(text(f"DROP TABLE IF EXISTS {tabellen_name};"))
        conn.execute(text(sql_befehl))

print("-" * 50)
print("Pipeline erfolgreich beendet! 4 Jahre Daten sind im Data Warehouse.")