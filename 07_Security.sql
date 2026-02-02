

-- Create the Roles 
IF DATABASE_PRINCIPAL_ID('db_Admin') IS NULL CREATE ROLE db_Admin;
IF DATABASE_PRINCIPAL_ID('db_Professor') IS NULL CREATE ROLE db_Professor;
IF DATABASE_PRINCIPAL_ID('db_Student') IS NULL CREATE ROLE db_Student;
GO

-- professor
GRANT SELECT ON View_Master_Schedule TO db_Professor;
GRANT SELECT ON View_Student_Transcript TO db_Professor;
GRANT SELECT ON View_Section_Enrollment TO db_Professor;
GRANT SELECT ON View_At_Risk_Students TO db_Professor;
GRANT SELECT ON View_Detailed_Gradebook TO db_Professor;
GRANT SELECT ON View_Waitlist_Queue TO db_Professor;
GO

GRANT EXECUTE ON sp_UpdateGrade TO db_Professor;
GRANT EXECUTE ON sp_CreateAssignment TO db_Professor;
GRANT EXECUTE ON sp_GradeSubmission TO db_Professor;
GRANT EXECUTE ON sp_GetClassRoster TO db_Professor;
GO

-- Deny
DENY DELETE ON Student TO db_Professor;
DENY DELETE ON Course TO db_Professor;
DENY DELETE ON Enrollment TO db_Professor;
GO

-- Students 
GRANT SELECT ON View_Master_Schedule TO db_Student;
GRANT SELECT ON View_Section_Enrollment TO db_Student;
GO
-- no execute permissions

-- Admins, full control
GRANT CONTROL ON SCHEMA::dbo TO db_Admin;
GO

GRANT SELECT ON View_Unpaid_Tuition TO db_Admin;
GRANT EXECUTE ON sp_AddNewStudent TO db_Admin;
GRANT EXECUTE ON sp_EnrollStudent TO db_Admin;
GRANT EXECUTE ON sp_WithdrawStudent TO db_Admin;
GRANT EXECUTE ON sp_GenerateTuitionBill TO db_Admin;
GRANT EXECUTE ON sp_PayTuitionBill TO db_Admin;
GO
