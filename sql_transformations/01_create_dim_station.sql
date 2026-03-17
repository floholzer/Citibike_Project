-- Erstelle die saubere Stations-Dimension ohne Duplikate
CREATE TABLE dim_station AS
WITH all_stations AS (
    SELECT start_station_id AS station_id, start_station_name AS station_name, start_lat AS lat, start_lng AS lng
    FROM staging_citibike_trips WHERE start_station_id IS NOT NULL
    UNION
    SELECT end_station_id AS station_id, end_station_name AS station_name, end_lat AS lat, end_lng AS lng
    FROM staging_citibike_trips WHERE end_station_id IS NOT NULL
),
grouped_stations AS (
    SELECT 
        station_id, 
        MAX(station_name) AS station_name, 
        MAX(lat) AS lat, 
        MAX(lng) AS lng
    FROM all_stations
    GROUP BY station_id
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY station_id) AS station_sk, -- Surrogate Key
    station_id, 
    station_name, 
    lat, 
    lng
FROM grouped_stations;