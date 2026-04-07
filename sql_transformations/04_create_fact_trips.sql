-- Erstelle die zentrale Faktentabelle
CREATE TABLE fact_trips AS
SELECT 
    -- 1. Die Foreign Keys (Surrogate Keys der Dimensionen)
    TO_CHAR(CAST(st.started_at AS TIMESTAMP)::DATE, 'YYYYMMDD')::INTEGER AS date_sk,
    TO_CHAR(CAST(st.ended_at AS TIMESTAMP)::DATE, 'YYYYMMDD')::INTEGER AS end_date_sk,
    ds_start.station_sk AS start_station_sk,
    db.bike_sk,
    du.user_sk,
    dw.weather_sk,
    
    -- 2. Measures auf dem aggregierten Fakt-Grain
    COUNT(*) AS trip_count,
    ROUND(
        AVG((EXTRACT(EPOCH FROM (CAST(st.ended_at AS TIMESTAMP) - CAST(st.started_at AS TIMESTAMP))) / 60)::NUMERIC),
        2
    ) AS avg_duration_minutes,
    ROUND(
        SUM((EXTRACT(EPOCH FROM (CAST(st.ended_at AS TIMESTAMP) - CAST(st.started_at AS TIMESTAMP))) / 60)::NUMERIC),
        2
    ) AS total_duration_minutes

FROM staging_citibike_trips st
LEFT JOIN dim_station ds_start ON st.start_station_id = ds_start.station_id
LEFT JOIN dim_bike db ON st.rideable_type = db.bike_type
LEFT JOIN dim_user_type du ON st.member_casual = du.user_type
LEFT JOIN dim_weather dw ON CAST(st.started_at AS TIMESTAMP)::DATE = dw.date_key
-- Wir nehmen nur Fahrten, die auch wirklich Stationen und Zeiten haben
WHERE st.start_station_id IS NOT NULL 
  AND st.started_at IS NOT NULL
    AND st.ended_at IS NOT NULL
    AND ds_start.station_sk IS NOT NULL
    AND db.bike_sk IS NOT NULL
    AND du.user_sk IS NOT NULL
    AND dw.weather_sk IS NOT NULL
GROUP BY
        TO_CHAR(CAST(st.started_at AS TIMESTAMP)::DATE, 'YYYYMMDD')::INTEGER,
        TO_CHAR(CAST(st.ended_at AS TIMESTAMP)::DATE, 'YYYYMMDD')::INTEGER,
        ds_start.station_sk,
        db.bike_sk,
        du.user_sk,
        dw.weather_sk;

-- PK auf aggregierten Surrogate Keys (komposite Schluesseldefinition)
ALTER TABLE fact_trips
ADD CONSTRAINT pk_fact_trips_sk
PRIMARY KEY (
        date_sk,
        end_date_sk,
        start_station_sk,
        bike_sk,
        user_sk,
        weather_sk
);