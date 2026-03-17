-- -- Erstelle die zentrale Faktentabelle
-- CREATE TABLE fact_trips AS
-- SELECT 
--     -- 1. Die eindeutige ID der Fahrt
--     ride_id,
    
--     -- 2. Die Foreign Keys (Schlüssel zu unseren Dimensionstabellen)
--     CAST(started_at AS TIMESTAMP)::DATE AS date_key,
--     start_station_id,
--     end_station_id,
--     rideable_type AS bike_type,
    
--     -- 3. Unsere Metrik (Measure): Fahrtdauer in Minuten berechnen
--     -- Wir ziehen Startzeit von Endzeit ab und rechnen es in Minuten um
--     ROUND(
--         (EXTRACT(EPOCH FROM (CAST(ended_at AS TIMESTAMP) - CAST(started_at AS TIMESTAMP))) / 60)::NUMERIC, 
--         2
--     ) AS duration_minutes

-- FROM staging_citibike_trips
-- -- Wir nehmen nur Fahrten, die auch wirklich Stationen und Zeiten haben
-- WHERE start_station_id IS NOT NULL 
--   AND end_station_id IS NOT NULL
--   AND started_at IS NOT NULL
--   AND ended_at IS NOT NULL;

-- -- Zur Kontrolle: Zeige uns die ersten 10 Fakten
-- SELECT * FROM fact_trips LIMIT 10;

-- Erstelle die zentrale Faktentabelle
CREATE TABLE fact_trips AS
SELECT 
    -- 1. Eigener Surrogate Key für den Fakt
    ROW_NUMBER() OVER (ORDER BY st.started_at) AS trip_sk,
    
    -- 2. Business Key aus dem Quellsystem behalten
    st.ride_id,
    
    -- 3. Die Foreign Keys (Surrogate Keys der Dimensionen)
    TO_CHAR(CAST(st.started_at AS TIMESTAMP)::DATE, 'YYYYMMDD')::INTEGER AS date_sk,
    ds_start.station_sk AS start_station_sk,
    ds_end.station_sk AS end_station_sk,
    db.bike_sk,
    du.user_sk,
    dw.weather_sk,
    
    -- 4. Unsere Metrik (Measure): Fahrtdauer in Minuten berechnen
    -- Wir ziehen Startzeit von Endzeit ab und rechnen es in Minuten um
    ROUND(
        (EXTRACT(EPOCH FROM (CAST(st.ended_at AS TIMESTAMP) - CAST(st.started_at AS TIMESTAMP))) / 60)::NUMERIC, 
        2
    ) AS duration_minutes

FROM staging_citibike_trips st
LEFT JOIN dim_station ds_start ON st.start_station_id = ds_start.station_id
LEFT JOIN dim_station ds_end ON st.end_station_id = ds_end.station_id
LEFT JOIN dim_bike db ON st.rideable_type = db.bike_type
LEFT JOIN dim_user_type du ON st.member_casual = du.user_type
LEFT JOIN dim_weather dw ON CAST(st.started_at AS TIMESTAMP)::DATE = dw.date_key
-- Wir nehmen nur Fahrten, die auch wirklich Stationen und Zeiten haben
WHERE st.start_station_id IS NOT NULL 
  AND st.end_station_id IS NOT NULL
  AND st.started_at IS NOT NULL
  AND st.ended_at IS NOT NULL;

-- Zur Kontrolle in VS Code
-- SELECT * FROM fact_trips LIMIT 10;