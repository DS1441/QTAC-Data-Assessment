USE QTAC_DataVault;
GO

CREATE VIEW gold.vw_ApplicantAdmissionSummary AS
WITH LatestApplicant AS (
    -- Get the most recent name/state for each student (SCD Type 2 logic) using placeholder startegy 
    SELECT hub_applicant_key, first_name, last_name, [state],
           ROW_NUMBER() OVER (PARTITION BY hub_applicant_key ORDER BY load_date DESC) as rn
    FROM dv.sat_applicant
),
HighestAcceptedPreference AS (
    -- Rule: Lowest preference_order representing highest preference
    SELECT lp.hub_applicant_key, lp.hub_course_key, sp.preference_order,
           ROW_NUMBER() OVER (PARTITION BY lp.hub_applicant_key ORDER BY sp.preference_order ASC) as rn
    FROM dv.link_preference lp
    JOIN dv.sat_link_preference sp ON lp.link_preference_key = sp.link_preference_key
    WHERE sp.response = 'Accepted'
),
LatestQual AS (
    -- Retrieving latest academic record
    SELECT hub_applicant_key, qualification_type, atar_score,
           ROW_NUMBER() OVER (PARTITION BY hub_applicant_key ORDER BY load_date DESC) as rn
    FROM dv.sat_qualification
)
SELECT 
    h.applicant_id,
    a.first_name + ' ' + a.last_name AS applicant_name,
    a.[state] AS applicant_state,
    sc.course_name AS accepted_course,
    sc.institution_name,
    q.qualification_type,
    q.atar_score
FROM dv.hub_applicant h
JOIN LatestApplicant a ON h.hub_applicant_key = a.hub_applicant_key AND a.rn = 1
JOIN HighestAcceptedPreference hap ON h.hub_applicant_key = hap.hub_applicant_key AND hap.rn = 1
JOIN dv.hub_course c ON hap.hub_course_key = c.hub_course_key
JOIN dv.sat_course sc ON c.hub_course_key = sc.hub_course_key
LEFT JOIN LatestQual q ON h.hub_applicant_key = q.hub_applicant_key AND q.rn = 1;
GO
