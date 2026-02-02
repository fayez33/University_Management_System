--  Register hadi
EXEC sp_AddNewStudent 
    @FirstName = 'hadi', 
    @LastName = 'Wonderland', 
    @Email = 'hadi@uni.edu', 
    @Phone = '555-9999', 
    @DOB = '2005-01-01', 
    @DeptID = 'CS';

-- try to enroll him in a class where the prerequisites are not met
DECLARE @hadiID INT = (SELECT person_id FROM Person WHERE email = 'hadi@uni.edu');
EXEC sp_EnrollStudent @StudentID = @hadiID, @SectionID = 2;





-- try to add him to a full class
DECLARE @hadiID INT = (SELECT person_id FROM Person WHERE email = 'hadi@uni.edu');
EXEC sp_EnrollStudent @StudentID = @hadiID, @SectionID = 3;
SELECT * FROM View_Waitlist_Queue WHERE section_id = 3; -- in the waiting list





-- a student from section 3 drops, hadi is automatically enrolled in the class
DELETE FROM Enrollment WHERE student_id = 3 AND section_id = 3;
SELECT * FROM View_Section_Enrollment WHERE section_id = 3;
SELECT * FROM Enrollment WHERE student_id = (SELECT person_id FROM Person WHERE email = 'hadi@uni.edu');






-- automatic grading system from assignment (or exam) submission 
SELECT student_id, gpa FROM Student WHERE student_id = (SELECT person_id FROM Person WHERE email = 'hadi@uni.edu');

DECLARE @hadiID INT = (SELECT person_id FROM Person WHERE email = 'hadi@uni.edu');
DECLARE @AssignID INT = 2; -- Midterm for CS101 (from Seed Data)
-- First, Enroll him in CS101 (Section 1) so she can be graded
EXEC sp_EnrollStudent @hadiID, 1; 
-- Now Grade him
EXEC sp_GradeSubmission @AssignmentID = @AssignID, @StudentID = @hadiID, @Score = 95.00;
-- Check the chain reaction results
SELECT 
    p.last_name,
    e.final_grade AS Course_Grade, -- Trigger 1 updated this
    s.gpa AS Total_GPA             -- Trigger 2 updated this
FROM Person p
JOIN Student s ON p.person_id = s.student_id
JOIN Enrollment e ON s.student_id = e.student_id
WHERE p.email = 'hadi@uni.edu' AND e.section_id = 1;




--  generate bill and view unpaid tuition
DECLARE @hadiID INT = (SELECT person_id FROM Person WHERE email = 'hadi@uni.edu');
EXEC sp_GenerateTuitionBill @StudentID = @hadiID, @Semester = 'Fall 2025';
SELECT * FROM View_Unpaid_Tuition WHERE email = 'hadi@uni.edu'; -- defined view 





-- soft delete
--  Withdraw hadi
DECLARE @hadiID INT = (SELECT person_id FROM Person WHERE email = 'hadi@uni.edu');
EXEC sp_WithdrawStudent @StudentID = @hadiID, @Reason = 'Demo Complete';
SELECT student_id, is_active FROM Student WHERE student_id = @hadiID; -- she is still present but inactive