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

ALTER TABLE dim_weather
ADD CONSTRAINT pk_dim_weather PRIMARY KEY (weather_sk);