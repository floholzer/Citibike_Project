-- Erstelle die zentrale Faktentabelle
CREATE TABLE fact_trips AS
SELECT 
    -- 1. Die eindeutige ID der Fahrt
    ride_id,
    
    -- 2. Die Foreign Keys (Schlüssel zu unseren Dimensionstabellen)
    CAST(started_at AS TIMESTAMP)::DATE AS date_key,
    start_station_id,
    end_station_id,
    rideable_type AS bike_type,
    
    -- 3. Unsere Metrik (Measure): Fahrtdauer in Minuten berechnen
    -- Wir ziehen Startzeit von Endzeit ab und rechnen es in Minuten um
    ROUND(
        (EXTRACT(EPOCH FROM (CAST(ended_at AS TIMESTAMP) - CAST(started_at AS TIMESTAMP))) / 60)::NUMERIC, 
        2
    ) AS duration_minutes

FROM staging_citibike_trips
-- Wir nehmen nur Fahrten, die auch wirklich Stationen und Zeiten haben
WHERE start_station_id IS NOT NULL 
  AND end_station_id IS NOT NULL
  AND started_at IS NOT NULL
  AND ended_at IS NOT NULL;

-- Zur Kontrolle: Zeige uns die ersten 10 Fakten
SELECT * FROM fact_trips LIMIT 10;