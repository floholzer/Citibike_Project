-- Erstelle die saubere Stations-Dimension ohne Duplikate
CREATE TABLE dim_station AS
WITH all_stations AS (
    SELECT start_station_id AS station_id, start_station_name AS station_name, start_lat AS lat, start_lng AS lng
    FROM staging_citibike_trips WHERE start_station_id IS NOT NULL
    UNION
    SELECT end_station_id AS station_id, end_station_name AS station_name, end_lat AS lat, end_lng AS lng
    FROM staging_citibike_trips WHERE end_station_id IS NOT NULL
)
SELECT DISTINCT station_id, station_name, lat, lng
FROM all_stations;

-- Zeige das Ergebnis
SELECT * FROM dim_station LIMIT 10;