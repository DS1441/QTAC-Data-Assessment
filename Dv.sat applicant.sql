USE QTAC_DataVault;
GO

-- 1. For Fresh start
TRUNCATE TABLE dv.sat_applicant;

-- 2. Loading Initial data from the source with de duplication
WITH InitialDeDup AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY applicant_id, created_date ORDER BY (SELECT NULL)) as rn
    FROM staging.applicants
)
INSERT INTO dv.sat_applicant (hub_applicant_key, load_date, first_name, last_name, email, state, postcode, record_source)
SELECT 
    HASHBYTES('SHA1', UPPER(TRIM(CAST(applicant_id AS NVARCHAR(50))))),
    CAST(created_date AS DATETIME),
    first_name, last_name, email, state, postcode,
    'staging.applicants'
FROM InitialDeDup
WHERE rn = 1;

-- 3. Delta Load for historical updates with Idempotent logic (ONLY if the Hash + Date combo is NEW)
WITH UpdateDeDup AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY applicant_id, updated_date ORDER BY (SELECT NULL)) as rn
    FROM staging.applicants_update
)
INSERT INTO dv.sat_applicant (hub_applicant_key, load_date, first_name, last_name, email, state, postcode, record_source)
SELECT 
    HASHBYTES('SHA1', UPPER(TRIM(CAST(src.applicant_id AS NVARCHAR(50))))),
    CAST(src.updated_date AS DATETIME),
    src.first_name, src.last_name, src.email, src.state, src.postcode,
    'staging.applicants_update'
FROM UpdateDeDup src
WHERE src.rn = 1
  
  AND NOT EXISTS (
      SELECT 1 FROM dv.sat_applicant target
      WHERE target.hub_applicant_key = HASHBYTES('SHA1', UPPER(TRIM(CAST(src.applicant_id AS NVARCHAR(50)))))
      AND target.load_date = CAST(src.updated_date AS DATETIME)
  );
