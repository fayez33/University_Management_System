
--show students info
CREATE OR ALTER VIEW View_Student_Transcript
AS
    SELECT
        st.student_id,
        p.first_name,
        p.last_name,
        p.email,
        c.title AS course_name,
        c.credits, 
        s.semester,
        e.final_grade,
        e.letter_grade,
        dbo.fn_GetStudentBalance(st.student_id) AS outstanding_balance
    FROM Person p
        JOIN Student st ON p.person_id = st.student_id
        JOIN Enrollment e ON st.student_id = e.student_id
        JOIN Section s ON e.section_id = s.section_id
        JOIN Course c ON s.course_id = c.course_id;
GO

-- department performance
CREATE OR ALTER VIEW View_Department_Performance
AS
    SELECT
        d.dept_name,
        COUNT(st.student_id) AS total_students,
        CAST(AVG(st.gpa) AS DECIMAL(5,2)) AS average_gpa
    FROM Department d
        LEFT JOIN Student st ON d.dept_id = st.dept_id
    GROUP BY d.dept_name;
GO

-- Shows who is teaching what where and when
CREATE VIEW View_Master_Schedule
AS
    SELECT
        p.last_name AS professor_name,
        c.course_id,
        c.title,
        s.semester,
        s.time_slot,
        r.building_name,
        r.room_number
    FROM Person p
        JOIN Professor prof ON p.person_id = prof.prof_id
        JOIN Section s ON prof.prof_id = s.prof_id
        JOIN Course c ON s.course_id = c.course_id
        JOIN Room r ON s.room_id = r.room_id;
GO

-- sees which sections are full
CREATE VIEW View_Section_Enrollment
AS
    SELECT
        c.course_id,
        c.title,
        s.section_id,
        s.semester,
        COUNT(e.student_id) AS enrolled_count,
        r.capacity,
        CAST((COUNT(e.student_id) * 100.0 / r.capacity) AS DECIMAL(5,2)) AS occupancy_rate
    FROM Section s
        JOIN Course c ON s.course_id = c.course_id
        JOIN Room r ON s.room_id = r.room_id
        LEFT JOIN Enrollment e ON s.section_id = e.section_id
    GROUP BY c.course_id, c.title, s.section_id, s.semester, r.capacity;
GO

-- students at risk (have a mark below 60)
CREATE VIEW View_At_Risk_Students
AS
    SELECT
        p.person_id,
        p.first_name,
        p.last_name,
        p.email,
        c.title AS failed_course,
        e.final_grade
    FROM Enrollment e
        JOIN Student s ON e.student_id = s.student_id
        JOIN Person p ON s.student_id = p.person_id
        JOIN Section sec ON e.section_id = sec.section_id
        JOIN Course c ON sec.course_id = c.course_id
    WHERE e.final_grade < 60;
GO

-- shows unpaid tuition bills
CREATE OR ALTER VIEW View_Unpaid_Tuition
AS
    SELECT
        p.person_id,
        p.first_name,
        p.last_name,
        p.email,
        tb.semester,
        tb.total_amount,
        tb.due_date,
        DATEDIFF(day, GETDATE(), tb.due_date) AS days_remaining
    FROM Person p
    JOIN Tuition_Bill tb ON p.person_id = tb.student_id
    WHERE tb.is_paid = 0;
GO


CREATE OR ALTER VIEW View_Detailed_Gradebook
AS
    SELECT
        c.course_id,
        s.section_id,
        a.title AS assignment_name,
        a.weight_percent,
        p.last_name + ', ' + p.first_name AS student_name,
        sub.score_obtained,
        a.max_points,
        CAST((sub.score_obtained / a.max_points * 100) AS DECIMAL(5,2)) AS percentage
    FROM Assignment a
    JOIN Section s ON a.section_id = s.section_id
    JOIN Course c ON s.course_id = c.course_id
    JOIN Student_Submission sub ON a.assignment_id = sub.assignment_id
    JOIN Person p ON sub.student_id = p.person_id;
GO


CREATE OR ALTER VIEW View_Waitlist_Queue
AS
    SELECT
        c.course_id,
        s.section_id,
        p.first_name,
        p.last_name,
        w.added_date,
        ROW_NUMBER() OVER(PARTITION BY w.section_id ORDER BY w.added_date ASC) AS queue_position -- shows position in queue
    FROM Waitlist w
    JOIN Section s ON w.section_id = s.section_id
    JOIN Course c ON s.course_id = c.course_id
    JOIN Person p ON w.student_id = p.person_id;
GO