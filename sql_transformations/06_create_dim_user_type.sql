-- Erstelle die User-Dimension (gemäß Star Schema: DIM_user_type)
CREATE TABLE dim_user_type AS
WITH unique_users AS (
    SELECT DISTINCT 
        member_casual AS user_type
    FROM staging_citibike_trips
    WHERE member_casual IS NOT NULL
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY user_type) AS user_sk, -- Surrogate Key
    user_type
FROM unique_users;

ALTER TABLE dim_user_type
ADD CONSTRAINT pk_dim_user_type PRIMARY KEY (user_sk);