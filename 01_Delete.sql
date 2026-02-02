
-- CLEANUP SCRIPT: UNIVERSAL RESET

PRINT 'STARTING CLEANUP';

-- 1. DROP PROCEDURES (Logic Layer)
DROP PROCEDURE IF EXISTS sp_AddNewStudent;
DROP PROCEDURE IF EXISTS sp_EnrollStudent;
DROP PROCEDURE IF EXISTS sp_UpdateGrade;
DROP PROCEDURE IF EXISTS sp_WithdrawStudent;
DROP PROCEDURE IF EXISTS sp_RecalculateStudentGPA;
DROP PROCEDURE IF EXISTS sp_GenerateTuitionBill;
DROP PROCEDURE IF EXISTS sp_PayTuitionBill;
DROP PROCEDURE IF EXISTS sp_CalculateFinalGradeFromAssignments;
DROP PROCEDURE IF EXISTS sp_CreateAssignment;
DROP PROCEDURE IF EXISTS sp_GradeSubmission;
DROP PROCEDURE IF EXISTS sp_GetClassRoster; 


DROP VIEW IF EXISTS View_Student_Transcript;
DROP VIEW IF EXISTS View_Department_Performance;
DROP VIEW IF EXISTS View_Master_Schedule;
DROP VIEW IF EXISTS View_Section_Enrollment;
DROP VIEW IF EXISTS View_At_Risk_Students;
DROP VIEW IF EXISTS View_Unpaid_Tuition;       
DROP VIEW IF EXISTS View_Detailed_Gradebook;    
DROP VIEW IF EXISTS View_Waitlist_Queue;        

-- 3. DROP TABLES (Data Layer)
DROP TABLE IF EXISTS Student_Submission; 
DROP TABLE IF EXISTS Assignment;    
DROP TABLE IF EXISTS Tuition_Bill;  
DROP TABLE IF EXISTS Waitlist;      
DROP TABLE IF EXISTS Grade_Audit_Log;
DROP TABLE IF EXISTS Enrollment;    
DROP TABLE IF EXISTS Prerequisite;  
DROP TABLE IF EXISTS Section;       
DROP TABLE IF EXISTS Course;        
DROP TABLE IF EXISTS Student;       
DROP TABLE IF EXISTS Professor;     
DROP TABLE IF EXISTS Room;
DROP TABLE IF EXISTS Person;
DROP TABLE IF EXISTS Department;

-- 4. DROP FUNCTIONS 
DROP FUNCTION IF EXISTS dbo.fn_GetLetterGrade;
DROP FUNCTION IF EXISTS dbo.fn_GetStudentBalance;
DROP FUNCTION IF EXISTS dbo.fn_CheckPrerequisites;

-- 5. DROP ROLES 
DROP ROLE IF EXISTS db_Admin;
DROP ROLE IF EXISTS db_Professor;
DROP ROLE IF EXISTS db_Student;

PRINT 'DATABASE IS EMPTY';
GO