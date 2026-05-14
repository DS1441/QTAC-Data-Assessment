USE QTAC_DataVault;
GO

-- 1. Integration loading of the data Using a JOIN to ignore orphan records
INSERT INTO dv.sat_qualification (hub_applicant_key, load_date, qualification_type, atar_score)
SELECT 
    h.hub_applicant_key,
    GETDATE(),
    q.qualification_type,
    TRY_CAST(q.atar_score AS DECIMAL(5,2))
FROM staging.qualifications q
--  If the ID isn't in the Hub, this record gets dropped.
INNER JOIN dv.hub_applicant h ON 
    h.hub_applicant_key = HASHBYTES('SHA1', UPPER(TRIM(CAST(q.applicant_id AS NVARCHAR(50)))))
WHERE q.applicant_id IS NOT NULL;
