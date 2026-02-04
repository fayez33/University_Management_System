
-- CLEANUP (Ensure test is repeatable)
DECLARE @ExistingPersonID INT;
SELECT @ExistingPersonID = person_id FROM Person WHERE email = 'test.user@uni.edu';

IF @ExistingPersonID IS NOT NULL
BEGIN
    PRINT 'Cleaning up previous test user...';
    DELETE FROM Tuition_Bill WHERE student_id = @ExistingPersonID;
    DELETE FROM Student_Submission WHERE student_id = @ExistingPersonID;
    DELETE FROM Enrollment WHERE student_id = @ExistingPersonID;
    DELETE FROM Person WHERE person_id = @ExistingPersonID; -- Cascades to Student
END

-- TEST 1: New Student Lifecycle
PRINT '--- Test 1: New Student Lifecycle ---';

-- 1.1 Add a new student
EXEC sp_AddNewStudent 
    @FirstName = 'Test', 
    @LastName = 'User', 
    @Email = 'test.user@uni.edu', 
    @Phone = '555-TEST', 
    @DOB = '2000-01-01', 
    @DeptID = 'CS';

DECLARE @NewStudentID INT;
SELECT @NewStudentID = person_id FROM Person WHERE email = 'test.user@uni.edu';
PRINT 'Created Student ID: ' + CAST(@NewStudentID AS VARCHAR);
SELECT * From Person WHERE email = 'test.user@uni.edu';


-- TEST 2: Prerequisites & Enrollment
PRINT '--- Test 2: Prerequisite Check ---';

-- EXPECTED: Error "Student has not met the prerequisites"
EXEC sp_EnrollStudent @StudentID = @NewStudentID, @SectionID = 2;

-- 2.2 Enroll in CS101 (Section 1) - Should Succeed
PRINT 'Attempting to enroll in CS101 (No Prereqs)...';
EXEC sp_EnrollStudent @StudentID = @NewStudentID, @SectionID = 1;


-- TEST 3: Assignments & Auto-Grading
PRINT '--- Test 3: Assignments & Auto-Grading ---';

-- 3.0 PREP: Clear existing assignments for Section 1
DELETE FROM Student_Submission WHERE assignment_id IN (SELECT assignment_id FROM Assignment WHERE section_id = 1);
DELETE FROM Assignment WHERE section_id = 1;

-- 3.1 Professor creates a new Assignment
EXEC sp_CreateAssignment 
    @SectionID = 1, 
    @Title = 'Surprise Quiz', 
    @MaxPoints = 100.00, 
    @Weight = 20.00;

-- 3.1b Fetch the ID properly (Scope_Identity cannot see inside the proc)
DECLARE @NewAssignmentID INT;
SELECT TOP 1 @NewAssignmentID = assignment_id 
FROM Assignment 
WHERE section_id = 1 AND title = 'Surprise Quiz'
ORDER BY assignment_id DESC;

PRINT 'Debug: Captured Assignment ID is ' + CAST(ISNULL(@NewAssignmentID, 0) AS VARCHAR);

-- SAFETY CHECK
IF @NewAssignmentID IS NULL
BEGIN
    PRINT 'CRITICAL ERROR: Assignment creation failed. Test aborted.';
END
ELSE
BEGIN
    -- 3.2 Grade the student
    EXEC sp_GradeSubmission 
        @AssignmentID = @NewAssignmentID, 
        @StudentID = @NewStudentID, 
        @Score = 90.00;

    -- 3.3 Verify Auto-Calculation Trigger
    SELECT 
        e.student_id,
        c.title AS Course,
        e.final_grade AS Calculated_Grade, 
        e.letter_grade
    FROM Enrollment e
    JOIN Section s ON e.section_id = s.section_id
    JOIN Course c ON s.course_id = c.course_id
    WHERE e.student_id = @NewStudentID AND e.section_id = 1;
END


-- TEST 4: Finance Module
PRINT '--- Test 4: Tuition & Billing ---';

-- 4.1 Generate Bill for Fall 2025
EXEC sp_GenerateTuitionBill @StudentID = @NewStudentID, @Semester = 'Fall 2025';

-- 4.2 Check Balance Function
DECLARE @Balance DECIMAL(10,2);
SET @Balance = dbo.fn_GetStudentBalance(@NewStudentID);
PRINT 'Current Balance Due: $' + CAST(@Balance AS VARCHAR);

-- 4.3 Pay the Bill
DECLARE @BillID INT;
SELECT @BillID = bill_id FROM Tuition_Bill WHERE student_id = @NewStudentID;
EXEC sp_PayTuitionBill @BillID = @BillID;

-- 4.4 Verify Balance is now 0
SET @Balance = dbo.fn_GetStudentBalance(@NewStudentID);
PRINT 'Balance After Payment: $' + CAST(@Balance AS VARCHAR);


-- TEST 5: Time Conflict Trigger
PRINT '--- Test 5: Time Conflict Trigger ---';

-- 5.1 Create a temporary conflicting section (Same time as Section 1: MWF 10:00)
INSERT INTO Section (course_id, prof_id, room_id, semester, time_slot)
VALUES ('EE200', 1, 1, 'Fall 2025', 'MWF 10:00-11:00');
DECLARE @ConflictingSectionID INT = SCOPE_IDENTITY();

-- 5.2 Try to enroll the same student
BEGIN TRY
    INSERT INTO Enrollment (student_id, section_id)
    VALUES (@NewStudentID, @ConflictingSectionID);
    PRINT 'FAILURE: Conflict Trigger did NOT stop the insertion.';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Conflict Trigger caught the error: ' + ERROR_MESSAGE();
END CATCH

DELETE FROM Section WHERE section_id = @ConflictingSectionID;


-- TEST 6: Waitlist Automation
PRINT '--- Test 6: Waitlist Automation ---';

-- Setup: Section 3 is FULL. Student 7 is on Waitlist.
-- 6.1 Student 8 drops Section 3
DELETE FROM Enrollment WHERE student_id = 8 AND section_id = 3;

-- 6.2 Verify Promotion (Student 7 moves from Waitlist -> Enrollment)
IF EXISTS (SELECT 1 FROM Enrollment WHERE student_id = 7 AND section_id = 3)
   AND NOT EXISTS (SELECT 1 FROM Waitlist WHERE student_id = 7 AND section_id = 3)
BEGIN
    PRINT 'SUCCESS: Student 7 was auto-promoted.';
END
ELSE
BEGIN
    PRINT 'FAILURE: Waitlist promotion did not occur.';
END


-- TEST 7: Views & Reporting
PRINT '--- Test 7: Verifying Views ---';

PRINT 'View_Student_Transcript (Now shows Balance & Credits):';
SELECT TOP 1 * FROM View_Student_Transcript 
WHERE student_id = @NewStudentID;


-- TEST 8: Withdrawal (Soft Delete)
PRINT '--- Test 8: Withdraw Student ---';

EXEC sp_WithdrawStudent 
    @StudentID = @NewStudentID, 
    @Reason = 'Transferring out';

-- Verify is_active = 0
SELECT student_id, is_active FROM Student WHERE student_id = @NewStudentID;
PRINT '>>> TEST SUITE COMPLETE.';
GO

-- Ad-hoc Reporting Checks
SELECT * FROM View_Unpaid_Tuition;
SELECT * FROM View_Detailed_Gradebook WHERE assignment_name = 'Surprise Quiz';
SELECT * FROM View_Waitlist_Queue WHERE course_id = 'PHYS101';
