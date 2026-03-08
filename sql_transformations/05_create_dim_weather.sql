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
SELECT 
    -- Wir stellen sicher, dass der Schlüssel ein echtes Datumsformat ist
    CAST(date_key AS DATE) AS date_key,
    
    -- Unsere Messwerte
    temp_max_celsius,
    temp_min_celsius,
    precipitation_mm,
    
    -- VERBESSERTE LOGIK: 
    -- Wir unterteilen Regen in 3 sinnvolle Kategorien, basierend auf unserer Datenanalyse (EDA).
    -- Die Zahlen am Anfang (1_, 2_, 3_) helfen Power BI später, die Balken richtig zu sortieren!
    CASE 
        WHEN precipitation_mm = 0 THEN '1_Trocken'
        WHEN precipitation_mm > 0 AND precipitation_mm <= 5 THEN '2_Leichter Regen (0-5mm)'
        ELSE '3_Starker Regen (>5mm)'
    END AS weather_condition

FROM staging_weather_historical;