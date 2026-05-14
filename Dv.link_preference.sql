USE QTAC_DataVault;
GO

-- 1. Creating the Link table  to manage the many to many relationship between applicants and Courses
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'link_preference' AND schema_id = SCHEMA_ID('dv'))
BEGIN
    CREATE TABLE dv.link_preference (
        link_preference_key BINARY(20) PRIMARY KEY,
        hub_applicant_key BINARY(20) NOT NULL,
        hub_course_key BINARY(20) NOT NULL,
        load_date DATETIME DEFAULT GETDATE(),
        record_source NVARCHAR(100),
        -- Ensuring the link only connects to existing Hubs
        FOREIGN KEY (hub_applicant_key) REFERENCES dv.hub_applicant(hub_applicant_key),
        FOREIGN KEY (hub_course_key) REFERENCES dv.hub_course(hub_course_key)
    );
END
GO

-- 2. Populating the Link from staging.preferences
INSERT INTO dv.link_preference (link_preference_key, hub_applicant_key, hub_course_key, record_source)
SELECT DISTINCT 
    -- Hashing the Applicant ID and Course Code together to make a unique relationship key
    HASHBYTES('SHA1', UPPER(TRIM(CAST(applicant_id AS NVARCHAR(50)))) + '|' + UPPER(TRIM(CAST(course_code AS NVARCHAR(50))))),
    HASHBYTES('SHA1', UPPER(TRIM(CAST(applicant_id AS NVARCHAR(50))))),
    HASHBYTES('SHA1', UPPER(TRIM(CAST(course_code AS NVARCHAR(50))))),
    'staging.preferences'
FROM staging.preferences
WHERE applicant_id IS NOT NULL AND course_code IS NOT NULL;
