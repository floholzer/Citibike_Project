-- Erstelle die User-Dimension (gemäß Star Schema: DIM_user_type)
CREATE TABLE dim_user_type AS
SELECT DISTINCT 
    member_casual AS user_type
FROM staging_citibike_trips
WHERE member_casual IS NOT NULL;

-- Zur Kontrolle in VS Code
-- SELECT * FROM dim_user_type;