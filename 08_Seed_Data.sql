
-- 1. DELETE DEEPEST DEPENDENCIES FIRST (Level 3)
DELETE FROM Student_Submission; 
DELETE FROM Assignment;
DELETE FROM Tuition_Bill;

-- 2. DELETE JUNCTION TABLES (Level 2)
DELETE FROM Waitlist;
DELETE FROM Grade_Audit_Log;
DELETE FROM Enrollment;
DELETE FROM Prerequisite;

-- 3. DELETE OPERATIONAL TABLES (Level 1)
DELETE FROM Section;

-- 4. DELETE MAIN ENTITIES (Level 0)
DELETE FROM Course;
DELETE FROM Student;
DELETE FROM Professor;
DELETE FROM Room;
DELETE FROM Person;
DELETE FROM Department;

-- Reseed Identity columns so IDs start at 1 again
DBCC CHECKIDENT ('Person', RESEED, 0);
DBCC CHECKIDENT ('Room', RESEED, 0);
DBCC CHECKIDENT ('Section', RESEED, 0);
DBCC CHECKIDENT ('Assignment', RESEED, 0);
DBCC CHECKIDENT ('Tuition_Bill', RESEED, 0);


INSERT INTO Department
    (dept_id, dept_name, office_location, budget)
VALUES
    ('CS', 'Computer Science', 'Engineering Bldg 3rd Floor', 500000.00),
    ('EE', 'Electrical Engineering', 'Engineering Bldg 1st Floor', 450000.00),
    ('MATH', 'Mathematics', 'Science Block A', 200000.00),
    ('PHYS', 'Physics', 'Science Block B', 300000.00);

SET IDENTITY_INSERT Person ON;
INSERT INTO Person
    (person_id, first_name, last_name, email, phone, dob)
VALUES
    (1, 'Alan', 'Turing', 'alan.turing@uni.edu', '555-0101', '1912-06-23'),
    (2, 'Grace', 'Hopper', 'grace.hopper@uni.edu', '555-0102', '1906-12-09'),
    (3, 'Richard', 'Feynman', 'r.feynman@uni.edu', '555-0103', '1918-05-11'),
    (4, 'Marie', 'Curie', 'm.curie@uni.edu', '555-0104', '1867-11-07'),

    (5, 'John', 'Doe', 'john.doe@student.uni.edu', '555-0201', '2003-05-15'),
    (6, 'Jane', 'Smith', 'jane.smith@student.uni.edu', '555-0202', '2004-08-20'),
    (7, 'Robert', 'Brown', 'bob.brown@student.uni.edu', '555-0203', '2002-11-01'),
    (8, 'Alice', 'Wonderland', 'alice.w@student.uni.edu', '555-0204', '2005-01-10'),
    (9, 'Charlie', 'Bucket', 'charlie.b@student.uni.edu', '555-0205', '2005-02-15');
SET IDENTITY_INSERT Person OFF;
DBCC CHECKIDENT ('Person', RESEED, 9);

INSERT INTO Professor
    (prof_id, dept_id, rank, office_number)
VALUES
    (1, 'CS', 'Full', 'EB-301'),
    (2, 'CS', 'Associate', 'EB-302'),
    (3, 'PHYS', 'Full', 'SB-101'),
    (4, 'PHYS', 'Assistant', 'SB-102');

INSERT INTO Student
    (student_id, dept_id, enrollment_date, gpa)
VALUES
    (5, 'CS', '2023-09-01', 3.85),
    (6, 'EE', '2024-09-01', 3.20),
    (7, 'CS', '2022-09-01', 2.90),
    (8, 'PHYS', '2024-09-01', 0.00),
    (9, 'MATH', '2024-09-01', 0.00);


SET IDENTITY_INSERT Room ON;
INSERT INTO Room
    (room_id, building_name, room_number, capacity)
VALUES
    (1, 'Eng Bldg', '101', 50),
    (2, 'Eng Bldg', '102', 30),
    (3, 'Sci Block', 'A10', 100),
    (4, 'Sci Block', 'B1', 2);
SET IDENTITY_INSERT Room OFF;
DBCC CHECKIDENT ('Room', RESEED, 4);

INSERT INTO Course
    (course_id, title, credits, dept_id)
VALUES
    ('CS101', 'Intro to Programming', 3, 'CS'),
    ('CS102', 'Data Structures', 4, 'CS'),
    ('EE200', 'Circuit Analysis', 4, 'EE'),
    ('MATH201', 'Linear Algebra', 3, 'MATH'),
    ('PHYS101', 'General Physics I', 4, 'PHYS');


INSERT INTO Prerequisite
    (course_id, req_course_id)
VALUES
    ('CS102', 'CS101'),
    ('EE200', 'PHYS101');

SET IDENTITY_INSERT Section ON;
INSERT INTO Section
    (section_id, course_id, prof_id, room_id, semester, time_slot)
VALUES

    (1, 'CS101', 1, 1, 'Fall 2025', 'MWF 10:00-11:00'),


    (2, 'CS102', 2, 2, 'Fall 2025', 'TTh 14:00-15:30'),

    (3, 'PHYS101', 3, 4, 'Fall 2025', 'MWF 09:00-10:00');
SET IDENTITY_INSERT Section OFF;
DBCC CHECKIDENT ('Section', RESEED, 3);


INSERT INTO Enrollment
    (student_id, section_id, final_grade)
VALUES

    (5, 1, 95.00),
    (6, 1, 82.50),
    (7, 1, 55.00),

    (5, 2, NULL),
    (8, 3, NULL),
    (9, 3, NULL);

INSERT INTO Waitlist
    (student_id, section_id)
VALUES
    (7, 3);