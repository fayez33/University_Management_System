CREATE OR ALTER TRIGGER trg_AuditGradeChanges
ON Enrollment
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Only log if the final grade changed
    IF UPDATE(final_grade)
    BEGIN
        INSERT INTO Grade_Audit_Log
            (student_id, section_id, old_grade, new_grade, changed_by)
        SELECT
            i.student_id,
            i.section_id,
            d.final_grade, -- Old value fromdeleted table
            i.final_grade, -- New value from inserted table
            SYSTEM_USER

        FROM inserted i
            JOIN deleted d ON i.student_id = d.student_id AND i.section_id = d.section_id
        WHERE i.final_grade <> d.final_grade; -- only change if the grades value was changed
    END
END;
GO

CREATE OR ALTER TRIGGER trg_PreventTimeConflict
ON Enrollment
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    -- check for any time conflict
    IF EXISTS (
        SELECT 1
    FROM Enrollment e
        --  Get details of classes the student is already in
        JOIN Section s_existing ON e.section_id = s_existing.section_id
        --  Join with inserted 
        JOIN inserted i ON e.student_id = i.student_id
        JOIN Section s_new ON s_new.section_id = i.section_id
    WHERE
        s_existing.section_id <> s_new.section_id -- compare the class to other classes only
        AND s_existing.semester = s_new.semester --  same semester
        AND s_existing.time_slot = s_new.time_slot --  same time
    )
    BEGIN
        -- if there is a match there is a time conflict
        ROLLBACK TRANSACTION;
        RAISERROR ('Error: Time Conflict! Student is already in a class at this time.', 16, 1);
    END
END;
GO

CREATE OR ALTER TRIGGER trg_AutoCalculateLetterGrade
ON Enrollment
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(final_grade) RETURN;

    UPDATE e
    SET e.letter_grade = dbo.fn_GetLetterGrade(i.final_grade)
    FROM Enrollment e
        INNER JOIN inserted i ON e.student_id = i.student_id AND e.section_id = i.section_id
    WHERE i.final_grade IS NOT NULL;

    -- We use a cursor here because sp_RecalculateStudentGPA is designed for a single student
    DECLARE @StudentToUpdate INT;
    DECLARE cur_GPA CURSOR FOR 
        SELECT DISTINCT student_id
    FROM inserted;

    OPEN cur_GPA;
    FETCH NEXT FROM cur_GPA INTO @StudentToUpdate;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC sp_RecalculateStudentGPA @StudentToUpdate;
        FETCH NEXT FROM cur_GPA INTO @StudentToUpdate;
    END

    CLOSE cur_GPA;
    DEALLOCATE cur_GPA;
END;
GO

CREATE OR ALTER TRIGGER trg_PromoteFromWaitlist
ON Enrollment
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DroppedSectionID INT;
    DECLARE @DropCount INT;
    DECLARE @NextStudentID INT;

    -- Cursor to handle multiple drops. 
    -- We group by section_id to know HOW MANY people dropped that specific section.
    DECLARE cur_Drops CURSOR FOR 
        SELECT section_id, COUNT(*)
    FROM deleted
    GROUP BY section_id;

    OPEN cur_Drops;
    FETCH NEXT FROM cur_Drops INTO @DroppedSectionID, @DropCount;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Loop as many times as there were drops for this section
        WHILE @DropCount > 0
        BEGIN
            -- 2. Find the FIRST person in the queue (Oldest added_date)
            SET @NextStudentID = NULL;

            SELECT TOP 1
                @NextStudentID = student_id
            FROM Waitlist
            WHERE section_id = @DroppedSectionID
            ORDER BY added_date ASC;

            -- 3. If someone is waiting, move them!
            IF @NextStudentID IS NOT NULL
            BEGIN
                BEGIN TRY
                    -- A. Move to Enrollment
                    INSERT INTO Enrollment
                    (student_id, section_id)
                VALUES
                    (@NextStudentID, @DroppedSectionID);

                    -- B. Remove from Waitlist
                    DELETE FROM Waitlist 
                    WHERE student_id = @NextStudentID AND section_id = @DroppedSectionID;

                    PRINT 'Auto-Promotion: Student ' + CAST(@NextStudentID AS VARCHAR) + ' moved from Waitlist to Class.';
                END TRY
                BEGIN CATCH
                    PRINT 'Could not promote student (Conflict?): ' + ERROR_MESSAGE();
                END CATCH
            END

            SET @DropCount = @DropCount - 1;
        END

        FETCH NEXT FROM cur_Drops INTO @DroppedSectionID, @DropCount;
    END

    CLOSE cur_Drops;
    DEALLOCATE cur_Drops;
END;
GO

CREATE OR ALTER TRIGGER trg_AutoUpdateFinalGradeFromAssignments
ON Student_Submission
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StudentID INT;
    DECLARE @SectionID INT;
    
    SELECT TOP 1 
        @StudentID = i.student_id, 
        @SectionID = a.section_id
    FROM inserted i
    JOIN Assignment a ON i.assignment_id = a.assignment_id;
    EXEC sp_CalculateFinalGradeFromAssignments @StudentID, @SectionID;
END;
GO

CREATE OR ALTER TRIGGER trg_AutoUpdateGPA
ON Enrollment
AFTER UPDATE, INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(final_grade)
    BEGIN
        DECLARE @StudentID INT;
        
        -- get dtudent ID
        SELECT TOP 1 @StudentID = student_id FROM inserted;

        -- Run stored procedure
        IF @StudentID IS NOT NULL
        BEGIN
            EXEC sp_RecalculateStudentGPA @StudentID;
        END
    END
END;
GO