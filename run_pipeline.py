# 1. Test mit nur einem Monat (Juli 2023) - schneller Durchlauf für die Entwicklung
# import os
# import requests
# import pandas as pd
# from zipfile import ZipFile
# from io import BytesIO
# from sqlalchemy import create_engine, text

# # 1. Datenbank-Verbindung herstellen
# db_url = 'postgresql://admin:password123@localhost:5432/citibike_dwh'
# engine = create_engine(db_url)

# print("STARTE ELT-PIPELINE...")
# print("-" * 40)

# # ==========================================
# # PHASE 1: EXTRACT & LOAD (Fahrräder)
# # ==========================================
# print("📦 Schritt 1: Lade Citi Bike Daten (Juli 2023) herunter...")
# url_bike = "https://s3.amazonaws.com/tripdata/JC-202307-citibike-tripdata.csv.zip"
# response = requests.get(url_bike)
# zip_file = ZipFile(BytesIO(response.content))
# csv_filename = zip_file.namelist()[0]

# with zip_file.open(csv_filename) as f:
#     # Wir laden weiterhin 10.000 Zeilen für einen schnellen Durchlauf
#     bike_df = pd.read_csv(f, nrows=10000)

# print("💾 Speichere Fahrräder in Staging-Tabelle...")
# bike_df.to_sql('staging_citibike_trips', engine, if_exists='replace', index=False)
# print("✅ Citi Bike Staging abgeschlossen!\n")


# # ==========================================
# # PHASE 2: EXTRACT & LOAD (Wetter)
# # ==========================================
# print("⛅ Schritt 2: Lade historische Wetterdaten (Juli 2023) herunter...")
# url_weather = "https://archive-api.open-meteo.com/v1/archive?latitude=40.7143&longitude=-74.006&start_date=2023-07-01&end_date=2023-07-31&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=America%2FNew_York"
# response_weather = requests.get(url_weather)
# data_weather = response_weather.json()

# weather_df = pd.DataFrame({
#     'date_key': data_weather['daily']['time'],
#     'temp_max_celsius': data_weather['daily']['temperature_2m_max'],
#     'temp_min_celsius': data_weather['daily']['temperature_2m_min'],
#     'precipitation_mm': data_weather['daily']['precipitation_sum']
# })

# print("💾 Speichere Wetter in Staging-Tabelle...")
# weather_df.to_sql('staging_weather_historical', engine, if_exists='replace', index=False)
# print("✅ Wetter Staging abgeschlossen!\n")


# # ==========================================
# # PHASE 3: TRANSFORM (SQL-Skripte ausführen)
# # ==========================================
# print("🔄 Schritt 3: Starte SQL-Transformationen (Star Schema)...")
# sql_folder = 'sql_transformations'

# # Wir holen uns alle SQL-Dateien aus dem Ordner und sortieren sie alphabetisch (01 -> 05)
# sql_files = sorted([f for f in os.listdir(sql_folder) if f.endswith('.sql')])

# # Wir öffnen eine sichere Verbindung zur Datenbank, um die Skripte auszuführen
# with engine.begin() as conn:
#     for file in sql_files:
#         print(f"   Führe aus: {file} ...")
#         file_path = os.path.join(sql_folder, file)
        
#         # SQL-Code aus der Datei lesen
#         with open(file_path, 'r', encoding='utf-8') as f:
#             sql_query = f.read()
            
#         # SQL-Code auf der Datenbank ausführen (wir droppen die Tabelle vorher, falls sie existiert)
#         # Tabellenname aus dem Dateinamen extrahieren (z.B. dim_station aus 01_create_dim_station.sql)
#         table_name = file.replace('.sql', '').split('create_')[1]
#         conn.execute(text(f"DROP TABLE IF EXISTS {table_name};"))
        
#         # Das eigentliche CREATE TABLE Skript ausführen
#         conn.execute(text(sql_query))

# print("✅ Alle Transformationen abgeschlossen!")
# print("-" * 40)
# print(" ELT-PIPELINE ERFOLGREICH BEENDET! Das Data Warehouse ist bereit für Power BI.")


import requests
import pandas as pd
from zipfile import ZipFile
from io import BytesIO
from sqlalchemy import create_engine, text

# 1. Verbindung zur Datenbank
db_url = 'postgresql://admin:password123@localhost:5432/citibike_dwh'
engine = create_engine(db_url)

print("Starte ELT-Pipeline (Big Data Edition: 2022 - 2025)...")
print("-" * 50)

# ==========================================
# PHASE 1: Fahrräder (Extract & Load)
# ==========================================
print("1. Lade Citi Bike Daten...")

# Wichtig: Staging-Tabelle vorher leeren, damit wir keine Daten doppelt anhängen
with engine.begin() as conn:
    conn.execute(text("DROP TABLE IF EXISTS staging_citibike_trips;"))

# Wir gehen die Jahre 2022 bis 2025 durch
for year in range(2022, 2026):
    # In jedem Jahr gehen wir die 12 Monate durch
    for month in range(1, 13):
        month_str = f"{month:02d}" # Macht aus 1 eine "01"
        url_bike = f"https://s3.amazonaws.com/tripdata/JC-{year}{month_str}-citibike-tripdata.csv.zip"
        
        print(f"   -> Lade Monat {month_str}/{year}...")
        response = requests.get(url_bike)
        
        # Nur verarbeiten, wenn die Datei bei Citi Bike existiert
        if response.status_code == 200:
            zip_file = ZipFile(BytesIO(response.content))
            csv_filename = zip_file.namelist()[0]
            
            with zip_file.open(csv_filename) as f:
                # Chunking schützt den Arbeitsspeicher bei Millionen von Zeilen!
                for chunk in pd.read_csv(f, chunksize=50000, low_memory=False):
                    chunk.to_sql('staging_citibike_trips', engine, if_exists='append', index=False)
        else:
            print(f"   ⚠️ Datei für {month_str}/{year} nicht gefunden. Überspringe...")


# ==========================================
# PHASE 2: Wetter (Extract & Load)
# ==========================================
print("\n2. Lade historische Wetterdaten (2022 bis 2025)...")
url_weather = "https://archive-api.open-meteo.com/v1/archive?latitude=40.7143&longitude=-74.006&start_date=2022-01-01&end_date=2025-12-31&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=America%2FNew_York"
data_weather = requests.get(url_weather).json()

weather_df = pd.DataFrame({
    'date_key': data_weather['daily']['time'],
    'temp_max_celsius': data_weather['daily']['temperature_2m_max'],
    'temp_min_celsius': data_weather['daily']['temperature_2m_min'],
    'precipitation_mm': data_weather['daily']['precipitation_sum']
})
weather_df.to_sql('staging_weather_historical', engine, if_exists='replace', index=False)


# ==========================================
# PHASE 3: Transformation (Star Schema)
# ==========================================
print("\n3. Führe SQL-Transformationen aus...")

# Ganz simpel und transparent: Wir listen die Dateien in der richtigen Reihenfolge auf
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
        
        with open(pfad, 'r', encoding='utf-8') as f:
            sql_befehl = f.read()
            
        # Wir droppen die Tabelle vorher. Der Name wird aus dem Dateinamen abgeleitet.
        tabellen_name = datei.replace('.sql', '').replace('01_create_', '').replace('02_create_', '').replace('03_create_', '').replace('04_create_', '').replace('05_create_', '')
        conn.execute(text(f"DROP TABLE IF EXISTS {tabellen_name};"))
        
        # SQL-Skript auf der Datenbank ausführen
        conn.execute(text(sql_befehl))

print("-" * 50)
print("Pipeline erfolgreich beendet! 4 Jahre Daten sind im Data Warehouse.")









# 2. Vollständige Pipeline mit 4 Jahren Daten (2022-2025) - dauert länger, aber komplett 
# import os
# import requests
# import pandas as pd
# from zipfile import ZipFile
# from io import BytesIO
# from sqlalchemy import create_engine, text

# db_url = 'postgresql://admin:password123@localhost:5432/citibike_dwh'
# engine = create_engine(db_url)

# print("STARTE ELT-PIPELINE (BIG DATA EDITION)...")
# print("-" * 40)

# # ==========================================
# # PHASE 1: EXTRACT & LOAD (Fahrräder 2022-2025)
# # ==========================================
# print("📦 Schritt 1: Lade Citi Bike Daten (2022 bis 2025)...")

# # WICHTIG: Wir leeren die Staging-Tabelle einmal am Anfang, damit wir danach 
# # die Monate sauber unten dranhängen können (append), ohne Duplikate zu erzeugen.
# with engine.begin() as conn:
#     conn.execute(text("DROP TABLE IF EXISTS staging_citibike_trips;"))

# # Wir iterieren durch die Jahre und Monate
# for year in range(2022, 2026):
#     for month in range(1, 13):
#         # Formatierung: Macht aus 1 eine "01" für die URL
#         month_str = f"{month:02d}" 
#         url_bike = f"https://s3.amazonaws.com/tripdata/JC-{year}{month_str}-citibike-tripdata.csv.zip"
        
#         print(f"   -> Lade {year}-{month_str} herunter...")
#         response = requests.get(url_bike)
        
#         # Nur weitermachen, wenn die Datei auch wirklich existiert (HTTP 200) = Wichtig, damit wir nicht mit leeren Daten arbeiten oder die Pipeline wegen eines fehlenden Monats abbricht.
#         if response.status_code == 200:
#             zip_file = ZipFile(BytesIO(response.content))
#             csv_filename = zip_file.namelist()[0]
            
#             with zip_file.open(csv_filename) as f:
#                 # MAGIC TRICK: chunksize=50000 schützt deinen Arbeitsspeicher!
#                 for chunk in pd.read_csv(f, chunksize=50000, low_memory=False):
#                     chunk.to_sql('staging_citibike_trips', engine, if_exists='append', index=False)
#         else:
#             print(f"   ⚠️ Datei für {year}-{month_str} nicht gefunden. Überspringe...")

# print("✅ Citi Bike Staging abgeschlossen!\n")


# # ==========================================
# # PHASE 2: EXTRACT & LOAD (Wetter 2022-2025)
# # ==========================================
# print("⛅ Schritt 2: Lade historische Wetterdaten (2022 bis 2025)...")
# # URL angepasst auf 01.01.2022 bis 31.12.2025
# url_weather = "https://archive-api.open-meteo.com/v1/archive?latitude=40.7143&longitude=-74.006&start_date=2022-01-01&end_date=2025-12-31&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=America%2FNew_York"
# response_weather = requests.get(url_weather)
# data_weather = response_weather.json()

# weather_df = pd.DataFrame({
#     'date_key': data_weather['daily']['time'],
#     'temp_max_celsius': data_weather['daily']['temperature_2m_max'],
#     'temp_min_celsius': data_weather['daily']['temperature_2m_min'],
#     'precipitation_mm': data_weather['daily']['precipitation_sum']
# })

# weather_df.to_sql('staging_weather_historical', engine, if_exists='replace', index=False)
# print("✅ Wetter Staging abgeschlossen!\n")


# # ==========================================
# # PHASE 3: TRANSFORM (SQL-Skripte ausführen)
# # ==========================================
# print("🔄 Schritt 3: Starte SQL-Transformationen (Star Schema)...")
# sql_folder = 'sql_transformations'
# sql_files = sorted([f for f in os.listdir(sql_folder) if f.endswith('.sql')])

# with engine.begin() as conn:
#     for file in sql_files:
#         print(f"   Führe aus: {file} ...")
#         file_path = os.path.join(sql_folder, file)
        
#         with open(file_path, 'r', encoding='utf-8') as f:
#             sql_query = f.read()
            
#         table_name = file.replace('.sql', '').split('create_')[1]
#         conn.execute(text(f"DROP TABLE IF EXISTS {table_name};"))
#         conn.execute(text(sql_query))

# print("✅ Alle Transformationen abgeschlossen!")
# print("-" * 40)
# print("ELT-PIPELINE ERFOLGREICH BEENDET! 4 Jahre Daten sind im Star Schema.")