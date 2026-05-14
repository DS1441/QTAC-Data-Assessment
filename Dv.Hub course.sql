USE QTAC_DataVault;
GO

-- 1. Creates the Course Hub table 
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'hub_course' AND schema_id = SCHEMA_ID('dv'))
BEGIN
    CREATE TABLE dv.hub_course (
        hub_course_key BINARY(20) PRIMARY KEY, 
        course_code NVARCHAR(50) UNIQUE,       
        load_date DATETIME DEFAULT GETDATE(),
        record_source NVARCHAR(100)
    );
END
GO

-- 2. Loading course Hub from staging.courses table
INSERT INTO dv.hub_course (hub_course_key, course_code, record_source)
SELECT DISTINCT 
    HASHBYTES('SHA1', UPPER(TRIM(CAST(course_code AS NVARCHAR(50))))), 
    CAST(course_code AS NVARCHAR(50)), 
    'staging.courses'
FROM staging.courses
WHERE course_code IS NOT NULL;
