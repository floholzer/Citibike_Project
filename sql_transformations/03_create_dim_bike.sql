-- Erstelle die Fahrrad-Dimension
CREATE TABLE dim_bike AS
WITH unique_bikes AS (
    SELECT DISTINCT 
        rideable_type AS bike_type
    FROM staging_citibike_trips
    WHERE rideable_type IS NOT NULL
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY bike_type) AS bike_sk, -- Surrogate Key
    bike_type
FROM unique_bikes;

-- Zeige das Ergebnis
SELECT * FROM dim_bike;