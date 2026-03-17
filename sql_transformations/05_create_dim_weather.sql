-- -- Erstelle die Wetter-Dimension
-- CREATE TABLE dim_weather AS
-- SELECT 
--     -- Wir stellen sicher, dass der Schlüssel ein echtes Datumsformat ist
--     CAST(date_key AS DATE) AS date_key,
    
--     -- Unsere Messwerte
--     temp_max_celsius,
--     temp_min_celsius,
--     precipitation_mm,
    
--     -- Ein kleiner Data-Engineering-Bonus für Power BI: 
--     -- Wir erstellen eine Text-Spalte, die sagt, ob es an dem Tag geregnet hat!
--     CASE 
--         WHEN precipitation_mm > 0 THEN 'Rainy'
--         ELSE 'Dry'
--     END AS weather_condition

-- FROM staging_weather_historical;

-- -- Zur Kontrolle: Zeige uns die ersten 10 Tage
-- SELECT * FROM dim_weather LIMIT 10;


DROP TABLE IF EXISTS dim_weather;
-- Erstelle die Wetter-Dimension
CREATE TABLE dim_weather AS
WITH cleaned_weather AS (
    SELECT 
        CAST(date_key AS DATE) AS date_key,
        temp_max_celsius,
        temp_min_celsius,
        precipitation_mm,
        CASE 
            WHEN precipitation_mm = 0 THEN '1_Trocken'
            WHEN precipitation_mm > 0 AND precipitation_mm <= 5 THEN '2_Leichter Regen (0-5mm)'
            ELSE '3_Starker Regen (>5mm)'
        END AS weather_condition
    FROM staging_weather_historical
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY date_key) AS weather_sk, -- Surrogate Key
    TO_CHAR(date_key, 'YYYYMMDD')::INTEGER AS date_sk,   -- Smart Key (für Zuordnung zur Date Dim)
    date_key,
    temp_max_celsius,
    temp_min_celsius,
    precipitation_mm,
    weather_condition
FROM cleaned_weather;