CREATE OR ALTER PROCEDURE sp_AddNewStudent
    @FirstName VARCHAR(50),
    @LastName VARCHAR(50),
    @Email VARCHAR(100),
    @Phone VARCHAR(20),
    @DOB DATE,
    @DeptID VARCHAR(10),
    @InitialGPA DECIMAL(5,2) = 0.00 -- default
AS
BEGIN
    SET NOCOUNT ON; -- avoid annoying messages
    SET XACT_ABORT ON; -- ensures a transaction is fully rolled back if ana error occured

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Person
        (first_name, last_name, email, phone, dob)
    VALUES
        (@FirstName, @LastName, @Email, @Phone, @DOB);

        DECLARE @NewID INT = SCOPE_IDENTITY();

        INSERT INTO Student
        (student_id, dept_id, gpa)
    VALUES
        (@NewID, @DeptID, @InitialGPA);

        COMMIT TRANSACTION;
        PRINT 'Student created with ID: ' + CAST(@NewID AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Could not add student. ' + ERROR_MESSAGE();
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_EnrollStudent
    @StudentID INT,
    @SectionID INT
AS
BEGIN
    SET NOCOUNT ON;
DECLARE @CourseID VARCHAR(15);
SELECT @CourseID = course_id FROM Section WHERE section_id = @SectionID;

-- Check Prereqs
IF dbo.fn_CheckPrerequisites(@StudentID, @CourseID) = 0
BEGIN
    PRINT 'Error: Student has not met the prerequisites for ' + @CourseID;
    RETURN;
END
    SET XACT_ABORT ON;

    DECLARE @CurrentCount INT;
    DECLARE @MaxCapacity INT;

    -- Check Room Capacity: 
    SELECT @MaxCapacity = r.capacity
    FROM Section s
    JOIN Room r ON s.room_id = r.room_id
    WHERE s.section_id = @SectionID;

    IF @MaxCapacity IS NULL
    BEGIN
        PRINT 'Error: Section ID not found.';
        RETURN;
    END

    -- Count Current Enrollments: 
    SELECT @CurrentCount = COUNT(*)
    FROM Enrollment
    WHERE section_id = @SectionID;

    -- if room is full add to waitlist
    IF @CurrentCount >= @MaxCapacity
    BEGIN
        PRINT 'Notice: Section is full, Attempting to waitlist...';
        
        BEGIN TRY
            INSERT INTO Waitlist (student_id, section_id, added_date)
            VALUES (@StudentID, @SectionID, GETDATE());
            
            PRINT 'Student added to Waitlist position';
        END TRY
        BEGIN CATCH
            IF ERROR_NUMBER() = 2627 -- Violation of Unique Constraint (they are already in the waitlist) 
                PRINT 'Error: Student is already on the Waitlist for this section.';
            ELSE
                PRINT 'Error: Could not waitlist. ' + ERROR_MESSAGE();
        END CATCH
        
        RETURN; -- Stop here, do not enroll
    END

    -- IF NOT FULL Enroll Normally
    BEGIN TRY
        INSERT INTO Enrollment (student_id, section_id, enroll_date)
        VALUES (@StudentID, @SectionID, GETDATE());
        
        PRINT 'Success: Student enrolled.';
    END TRY
    BEGIN CATCH
        PRINT 'Error: Enrollment failed' + ERROR_MESSAGE(); -- maybe student is already enrolled
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_UpdateGrade
    @StudentID INT,
    @SectionID INT,
    @NewGrade DECIMAL(5,2)
AS
BEGIN
    -- Validate Grade Range (0-100)
    IF @NewGrade < 0 OR @NewGrade > 100
    BEGIN
        PRINT 'Error: Grade must be between 0 and 100.';
        RETURN;
    END

    UPDATE Enrollment
    SET final_grade = @NewGrade
    WHERE student_id = @StudentID AND section_id = @SectionID;

    IF @@ROWCOUNT = 0
        PRINT 'Error: No matching enrollment found to update.';
    ELSE
        PRINT 'Success: Grade updated.';
END;
GO

-- after new final igrade
CREATE OR ALTER PROCEDURE sp_RecalculateStudentGPA
    @StudentID INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NewGPA DECIMAL(5,2);

    SELECT @NewGPA = AVG(final_grade)
    FROM Enrollment
    WHERE student_id = @StudentID AND final_grade IS NOT NULL;

    -- Update the Student table
    UPDATE Student
    SET gpa = ISNULL(@NewGPA, 0.00) -- Set to 0 if no grades exist
    WHERE student_id = @StudentID;

    PRINT 'GPA updated to: ' + CAST(ISNULL(@NewGPA, 0.00) AS VARCHAR(10));
END;
GO

CREATE OR ALTER PROCEDURE sp_WithdrawStudent
    @StudentID INT,
    @Reason VARCHAR(255),
    @Semester VARCHAR(15) = NULL -- default to null
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    --  Check if student exists
    IF NOT EXISTS (SELECT 1 FROM Student WHERE student_id = @StudentID)
    BEGIN
        PRINT 'Error: Student not found.';
        RETURN;
    END

    BEGIN TRANSACTION;

    --  Mark the student as Inactive
    UPDATE Student 
    SET is_active = 0 
    WHERE student_id = @StudentID;

    PRINT 'Success: Student marked as inactive.';

    -- if he is already enrolled in a claas, drop it
    IF @Semester IS NOT NULL
    BEGIN
        DELETE FROM Enrollment
        WHERE student_id = @StudentID 
          AND section_id IN (SELECT section_id FROM Section WHERE semester = @Semester);
          
        PRINT 'Dropped all enrollments for ' + @Semester;
    END
    ELSE
    BEGIN
        PRINT 'No Semester provided. Enrollments were kept (only Student status changed).';
    END

    COMMIT TRANSACTION;
END;
GO

CREATE OR ALTER PROCEDURE sp_GenerateTuitionBill
    @StudentID INT,
    @Semester VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CreditCount INT;
    
    -- Calculate Total Credits for that Term
    SELECT @CreditCount = SUM(c.credits)
    FROM Enrollment e
    JOIN Section s ON e.section_id = s.section_id
    JOIN Course c ON s.course_id = c.course_id
    WHERE e.student_id = @StudentID AND s.semester = @Semester;

    IF @CreditCount IS NULL OR @CreditCount = 0
    BEGIN
        PRINT 'Error: Student is not enrolled in any classes for ' + @Semester;
        RETURN;
    END

    -- Insert or Uppdate Bill
    MERGE Tuition_Bill AS target
    USING (SELECT @StudentID AS sid, @Semester AS sem) AS source
    ON (target.student_id = source.sid AND target.semester = source.sem)
    WHEN MATCHED THEN
        UPDATE SET total_credits = @CreditCount
    WHEN NOT MATCHED THEN
        INSERT (student_id, semester, total_credits)
        VALUES (@StudentID, @Semester, @CreditCount);

    PRINT 'Bill generated for ' + CAST(@CreditCount AS VARCHAR) + ' credits.';
END;
GO


CREATE OR ALTER PROCEDURE sp_CalculateFinalGradeFromAssignments
    @StudentID INT,
    @SectionID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CalculatedGrade DECIMAL(5,2);

    SELECT @CalculatedGrade = SUM( (sub.score_obtained / a.max_points) * a.weight_percent )
    FROM Student_Submission sub
    JOIN Assignment a ON sub.assignment_id = a.assignment_id
    WHERE sub.student_id = @StudentID AND a.section_id = @SectionID;

    -- Update the main Enrollment table
    IF @CalculatedGrade IS NOT NULL
    BEGIN
        UPDATE Enrollment
        SET final_grade = @CalculatedGrade
        WHERE student_id = @StudentID AND section_id = @SectionID;
        
        PRINT 'Success: Grade updated to ' + CAST(@CalculatedGrade AS VARCHAR);
    END
END;
GO


CREATE OR ALTER PROCEDURE sp_PayTuitionBill
    @BillID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- does The Bill Exist
    IF NOT EXISTS (SELECT 1 FROM Tuition_Bill WHERE bill_id = @BillID)
    BEGIN
        PRINT 'Error: Bill ID not found.';
        RETURN;
    END

    --  Is it already paid
    IF EXISTS (SELECT 1 FROM Tuition_Bill WHERE bill_id = @BillID AND is_paid = 1)
    BEGIN
        PRINT 'Notice: This bill is already marked as paid.';
        RETURN;
    END

    --  Pay it
    UPDATE Tuition_Bill
    SET is_paid = 1
    WHERE bill_id = @BillID;

    PRINT 'Success: Payment recorded. Bill #' + CAST(@BillID AS VARCHAR) + ' is settled.';
END;
GO


CREATE OR ALTER PROCEDURE sp_CreateAssignment
    @SectionID INT,
    @Title VARCHAR(100),
    @MaxPoints DECIMAL(5,2) = 100.00,
    @Weight DECIMAL(5,2) 
AS
BEGIN
    DECLARE @CurrentWeight DECIMAL(5,2);
    SELECT @CurrentWeight = SUM(weight_percent) FROM Assignment WHERE section_id = @SectionID;
    
    IF (ISNULL(@CurrentWeight, 0) + @Weight) > 100
    BEGIN
        PRINT 'Error: Total weight cannot exceed 100%. Current: ' + CAST(@CurrentWeight AS VARCHAR);
        RETURN;
    END

    -- insert into assignments table
    INSERT INTO Assignment (section_id, title, max_points, weight_percent, due_date)
    VALUES (@SectionID, @Title, @MaxPoints, @Weight, DATEADD(day, 7, GETDATE()));
    
    PRINT 'Success: Assignment "' + @Title + '" created.';
END;
GO


CREATE OR ALTER PROCEDURE sp_GradeSubmission
    @AssignmentID INT,
    @StudentID INT,
    @Score DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert or Update the submission
    MERGE Student_Submission AS target
    USING (SELECT @AssignmentID AS aid, @StudentID AS sid) AS source
    ON (target.assignment_id = source.aid AND target.student_id = source.sid)
    WHEN MATCHED THEN
        UPDATE SET score_obtained = @Score, submission_date = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (assignment_id, student_id, score_obtained)
        VALUES (@AssignmentID, @StudentID, @Score);

    PRINT 'Success: Score recorded.';
END;
GO

-- list students in a specific section
CREATE OR ALTER PROCEDURE sp_GetClassRoster
    @SectionID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        c.course_id, 
        c.title, 
        s.time_slot, 
        r.room_number,
        COUNT(e.student_id) AS total_enrolled
    FROM Section s
    JOIN Course c ON s.course_id = c.course_id
    JOIN Room r ON s.room_id = r.room_id
    LEFT JOIN Enrollment e ON s.section_id = e.section_id
    WHERE s.section_id = @SectionID
    GROUP BY c.course_id, c.title, s.time_slot, r.room_number;

    -- The Student List
    SELECT 
        st.student_id,
        p.first_name,
        p.last_name,
        p.email,
        st.gpa,
        e.final_grade AS current_grade
    FROM Enrollment e
    JOIN Student st ON e.student_id = st.student_id
    JOIN Person p ON st.student_id = p.person_id
    WHERE e.section_id = @SectionID
    ORDER BY p.last_name ASC;
END;
GO