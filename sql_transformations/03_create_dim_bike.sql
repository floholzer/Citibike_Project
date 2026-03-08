-- Erstelle die Fahrrad-Dimension
CREATE TABLE dim_bike AS
SELECT DISTINCT 
    rideable_type AS bike_type
FROM staging_citibike_trips
WHERE rideable_type IS NOT NULL;

-- Zeige das Ergebnis
SELECT * FROM dim_bike;