-- 1. Wir erstellen die Zeit-Dimension
CREATE TABLE dim_date AS
WITH all_dates AS (
    -- Wir wandeln den Text-Zeitstempel in ein echtes Datum (ohne Uhrzeit) um
    SELECT CAST(started_at AS TIMESTAMP)::DATE AS date_val FROM staging_citibike_trips WHERE started_at IS NOT NULL
    UNION
    SELECT CAST(ended_at AS TIMESTAMP)::DATE AS date_val FROM staging_citibike_trips WHERE ended_at IS NOT NULL
)
-- 2. Wir reichern das Datum mit nützlichen Analyse-Spalten für Power BI an
SELECT DISTINCT 
    TO_CHAR(date_val, 'YYYYMMDD')::INTEGER AS date_sk, -- Smart Surrogate Key (z.B. 20240115)
    date_val AS date_key,
    EXTRACT(YEAR FROM date_val) AS year,
    EXTRACT(MONTH FROM date_val) AS month,
    EXTRACT(DAY FROM date_val) AS day,
    TRIM(TO_CHAR(date_val, 'Day')) AS day_of_week
FROM all_dates;

ALTER TABLE dim_date
ADD CONSTRAINT pk_dim_date PRIMARY KEY (date_sk);