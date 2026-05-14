USE QTAC_DataVault;
GO


TRUNCATE TABLE dv.sat_link_preference;

-- 2. Loading with de duplication fix
WITH DeDupedPrefs AS (
    SELECT 
        applicant_id, 
        course_code, 
        preference_order, 
        offer_status, 
        response,
        
        ROW_NUMBER() OVER (
            PARTITION BY applicant_id, course_code 
            ORDER BY (SELECT NULL)
        ) as rn
    FROM staging.preferences
)
INSERT INTO dv.sat_link_preference (link_preference_key, load_date, preference_order, offer_status, response)
SELECT 
    HASHBYTES('SHA1', UPPER(TRIM(CAST(applicant_id AS NVARCHAR(50)))) + '|' + UPPER(TRIM(CAST(course_code AS NVARCHAR(50))))),
    GETDATE(),
    CAST(preference_order AS INT),
    offer_status,
    response
FROM DeDupedPrefs
WHERE rn = 1; --  filter to avoid the duplicates
