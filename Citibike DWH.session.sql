-- Prüfen, ob die Stationen jetzt eindeutig sind und Durchschnitts-GPS haben
SELECT * FROM dim_station 
ORDER BY station_name 
LIMIT 10;

-- Prüfen, ob die Faktentabelle befüllt wurde
SELECT count(*) AS gesamtanzahl_fahrten 
FROM fact_trips;