-- finds the letter grade from the numeric grade
CREATE OR ALTER FUNCTION dbo.fn_GetLetterGrade (@Score DECIMAL(5,2))
RETURNS CHAR(2)
AS
BEGIN
    DECLARE @Letter CHAR(2);

    IF @Score IS NULL SET @Letter = NULL;
    ELSE IF @Score >= 90 SET @Letter = 'A';
    ELSE IF @Score >= 85 SET @Letter = 'B+';
    ELSE IF @Score >= 80 SET @Letter = 'B';
    ELSE IF @Score >= 75 SET @Letter = 'C+';
    ELSE IF @Score >= 70 SET @Letter = 'C';
    ELSE IF @Score >= 60 SET @Letter = 'D';
    ELSE SET @Letter = 'F';

    RETURN @Letter;
END;
GO

-- find the total debt for a student
CREATE OR ALTER FUNCTION dbo.fn_GetStudentBalance (@StudentID INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @TotalDebt DECIMAL(10, 2);
    
    SELECT @TotalDebt = SUM(total_amount)
    FROM Tuition_Bill
    WHERE student_id = @StudentID AND is_paid = 0;
    -- If no bills found return 0
    RETURN ISNULL(@TotalDebt, 0.00);
END;
GO

-- checks prerequisites for a course
CREATE OR ALTER FUNCTION dbo.fn_CheckPrerequisites (@StudentID INT, @CourseID VARCHAR(15))
RETURNS BIT
AS
BEGIN
 
    DECLARE @MissingPrereqs INT;

    SELECT @MissingPrereqs = COUNT(*)
    FROM Prerequisite p
    WHERE p.course_id = @CourseID -- The course they want to take
      AND p.req_course_id NOT IN ( -- Check if they have passed the requirement
          SELECT s.course_id
          FROM Enrollment e
          JOIN Section s ON e.section_id = s.section_id
          WHERE e.student_id = @StudentID 
            AND e.final_grade >= 60.00 -- Must have a passing grade
      );
    -- if no missinf prerequisites you can enroll
    IF @MissingPrereqs = 0
        RETURN 1; -- allowed to tae new class
    
    RETURN 0; -- notallowed
END;
GO