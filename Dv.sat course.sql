USE QTAC_DataVault;
GO

-- 1. Creates the Course Satellite Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'sat_course' AND schema_id = SCHEMA_ID('dv'))
BEGIN
    CREATE TABLE dv.sat_course (
        hub_course_key BINARY(20) NOT NULL,
        load_date DATETIME NOT NULL,
        course_name NVARCHAR(255),
        institution_name NVARCHAR(255),
        atar_cutoff DECIMAL(5,2),
        active_flag BIT,
        record_source NVARCHAR(100),
        PRIMARY KEY (hub_course_key, load_date),
        FOREIGN KEY (hub_course_key) REFERENCES dv.hub_course(hub_course_key)
    );
END
GO

-- 2. Loading the course details from staging.courses
INSERT INTO dv.sat_course (hub_course_key, load_date, course_name, institution_name, atar_cutoff, active_flag, record_source)
SELECT 
    HASHBYTES('SHA1', UPPER(TRIM(CAST(course_code AS NVARCHAR(50))))),
    GETDATE(), 
    course_name,
    institution_name,
    TRY_CAST(atar_cutoff AS DECIMAL(5,2)), 
    CASE WHEN active_flag = '1' THEN 1 ELSE 0 END,
    'staging.courses'
FROM staging.courses;
