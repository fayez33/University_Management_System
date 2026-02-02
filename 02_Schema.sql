CREATE TABLE Department (
    dept_id VARCHAR(10) PRIMARY KEY, 
    dept_name VARCHAR(100) NOT NULL,
    office_location VARCHAR(100),
    budget DECIMAL(15, 2) CHECK (budget >= 0)
);

CREATE TABLE Person (
    person_id INT IDENTITY(1,1) PRIMARY KEY, 
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE, 
    phone VARCHAR(20) UNIQUE,
    dob DATE NOT NULL
);

CREATE TABLE Room (
    room_id INT IDENTITY(1,1) PRIMARY KEY,
    building_name VARCHAR(50) NOT NULL,
    room_number VARCHAR(10) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0), 
    CONSTRAINT uq_room_location UNIQUE (building_name, room_number) 
);

CREATE TABLE Student (
    student_id INT PRIMARY KEY,
    dept_id VARCHAR(10) NOT NULL,
    enrollment_date DATE DEFAULT GETDATE(),
    is_active BIT DEFAULT 1,
    gpa DECIMAL(5, 2) DEFAULT 0.00 CHECK (gpa >= 0.00 AND gpa <= 100.00),
    CONSTRAINT fk_student_person FOREIGN KEY (student_id) REFERENCES Person(person_id) ON DELETE CASCADE,
    CONSTRAINT fk_student_dept FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
    
);
CREATE UNIQUE INDEX uq_person_phone ON Person(phone) WHERE phone IS NOT NULL;

CREATE TABLE Professor (
    prof_id INT PRIMARY KEY, 
    dept_id VARCHAR(10) NOT NULL,
    rank VARCHAR(50) CHECK (rank IN ('Assistant', 'Associate', 'Full', 'Adjunct')),
    office_number VARCHAR(20),
    CONSTRAINT fk_prof_person FOREIGN KEY (prof_id) REFERENCES Person(person_id) ON DELETE CASCADE, -- delete row in child when row in parent is deleted
    CONSTRAINT fk_prof_dept FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
);

CREATE TABLE Course (
    course_id VARCHAR(15) PRIMARY KEY, 
    title VARCHAR(150) NOT NULL,
    credits TINYINT NOT NULL CHECK (credits > 0 AND credits <= 6),
    dept_id VARCHAR(10) NOT NULL,
    CONSTRAINT fk_course_dept FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
);

CREATE TABLE Prerequisite (
    course_id VARCHAR(15),
    req_course_id VARCHAR(15),
    PRIMARY KEY (course_id, req_course_id), 
    CONSTRAINT fk_prereq_course FOREIGN KEY (course_id) REFERENCES Course(course_id),
    CONSTRAINT fk_prereq_required FOREIGN KEY (req_course_id) REFERENCES Course(course_id)
);

CREATE TABLE Section (
    section_id INT IDENTITY(1,1) PRIMARY KEY,
    course_id VARCHAR(15) NOT NULL,
    prof_id INT NOT NULL,
    room_id INT NOT NULL,
    semester VARCHAR(15) NOT NULL, 
    time_slot VARCHAR(50) NOT NULL, 
    CONSTRAINT fk_section_course FOREIGN KEY (course_id) REFERENCES Course(course_id),
    CONSTRAINT fk_section_prof FOREIGN KEY (prof_id) REFERENCES Professor(prof_id),
    CONSTRAINT fk_section_room FOREIGN KEY (room_id) REFERENCES Room(room_id)
);

CREATE TABLE Enrollment (
    student_id INT,
    section_id INT,
    enroll_date DATE DEFAULT GETDATE(),
    final_grade DECIMAL(5, 2) CHECK (final_grade >= 0.00 AND final_grade <= 100.00),
    letter_grade CHAR(2),
    PRIMARY KEY (student_id, section_id),
    CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES Student(student_id),
    CONSTRAINT fk_enroll_section FOREIGN KEY (section_id) REFERENCES Section(section_id)
);

CREATE TABLE Grade_Audit_Log (
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id INT,
    section_id INT,
    old_grade DECIMAL(5,2),
    new_grade DECIMAL(5,2),
    changed_by VARCHAR(100),
    change_date DATETIME DEFAULT GETDATE()
);

CREATE TABLE Waitlist (
    waitlist_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id INT NOT NULL,
    section_id INT NOT NULL,
    added_date DATETIME DEFAULT GETDATE(),
    CONSTRAINT uq_waitlist_entry UNIQUE (student_id, section_id),
    CONSTRAINT fk_waitlist_student FOREIGN KEY (student_id) REFERENCES Student(student_id),
    CONSTRAINT fk_waitlist_section FOREIGN KEY (section_id) REFERENCES Section(section_id),
);

CREATE TABLE Tuition_Bill (
    bill_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id INT NOT NULL,
    semester VARCHAR(15) NOT NULL, 
    total_credits TINYINT NOT NULL,
    cost_per_credit DECIMAL(10,2) DEFAULT 500.00, 
    total_amount AS (total_credits * cost_per_credit),
    is_paid BIT DEFAULT 0,
    due_date DATE DEFAULT DATEADD(day, 30, GETDATE()),
    CONSTRAINT fk_bill_student FOREIGN KEY (student_id) REFERENCES Student(student_id),
    CONSTRAINT uq_student_semester_bill UNIQUE (student_id, semester) 
);

CREATE TABLE Assignment (
    assignment_id INT IDENTITY(1,1) PRIMARY KEY,
    section_id INT NOT NULL,
    title VARCHAR(100) NOT NULL, 
    description VARCHAR(255),
    max_points DECIMAL(5,2) DEFAULT 100.00,
    weight_percent DECIMAL(5,2) NOT NULL, 
    due_date DATETIME,
    CONSTRAINT fk_assign_section FOREIGN KEY (section_id) REFERENCES Section(section_id)
);

CREATE TABLE Student_Submission (
    submission_id INT IDENTITY(1,1) PRIMARY KEY,
    assignment_id INT NOT NULL,
    student_id INT NOT NULL,
    score_obtained DECIMAL(5,2) CHECK (score_obtained >= 0),
    submission_date DATETIME DEFAULT GETDATE(),
    CONSTRAINT fk_sub_assign FOREIGN KEY (assignment_id) REFERENCES Assignment(assignment_id),
    CONSTRAINT fk_sub_student FOREIGN KEY (student_id) REFERENCES Student(student_id),
    CONSTRAINT uq_one_submission UNIQUE (assignment_id, student_id)
);
GO