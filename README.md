# University Management System (UMS) Database

> A robust, normalized relational database solution designed to automate the complete academic and financial lifecycle of a university, from admission to graduation.

## Executive Summary

The **University Management System (UMS)** is a backend solution built on **Microsoft SQL Server**. Unlike simple data stores, this project implements complex business logic directly within the database layer using Stored Procedures, Triggers, and Role-Based Access Control (RBAC).

It solves the "Spreadsheet Chaos" problem by providing a centralized source of truth for:
* **Identity Management:** Handling Students, Professors, and Admins via Table Inheritance.
* **Academic Operations:** Course scheduling, prerequisites enforcement, and waitlist management.
* **Automated Grading:** A "Chain Reaction" system where individual assignment scores automatically update course grades and cumulative GPAs.
* **Financials:** Tuition billing and payment tracking.

---

## Database Architecture & Core Tables

The schema follows **3rd Normal Form (3NF)** standards and utilizes a **Supertype/Subtype** design pattern to handle user identities efficiently.

### 1. Identity Module (Inheritance Model)
We utilize a "Table Inheritance" strategy to manage user data, reducing redundancy and ensuring data integrity.

* **`Person` (Base Entity)**
    * **Role:** The Supertype table.
    * **Data:** Stores common attributes for all users: `First Name`, `Last Name`, `DOB`, `Phone`, and a unique `Email`.
    * **Constraint:** Includes a **Unique Filtered Index** on `Phone` to allow NULLs but enforce uniqueness for provided numbers.

* **`Student` (Subtype)**
    * **Role:** Inherits from `Person`.
    * **Data:** Stores academic-specific data: `GPA` (auto-calculated), `Dept_ID`, and `Enrollment_Date`.
    * **Feature:** Implements a **Soft Delete** mechanism (`is_active` bit flag) to preserve academic history after withdrawal.

* **`Professor` (Subtype)**
    * **Role:** Inherits from `Person`.
    * **Data:** Stores faculty-specific data: `Hire_Date` and `Rank`.

### 2. Academic Catalog Module
This module distinguishes between the abstract "Course" and the concrete "Section" to allow for flexible scheduling.

* **`Department`**
    * **Role:** The organizational unit (e.g., Computer Science, Engineering).
    * **Data:** Department Codes and Names.

* **`Course` (The Catalog)**
    * **Role:** Defines the abstract subject matter.
    * **Data:** `Course_ID` (e.g., "CS101"), `Title`, and `Credits`.
    * **Logic:** Acts as the parent for all sections.

* **`Section` (The Schedule)**
    * **Role:** A specific instance of a course offered in a specific semester.
    * **Data:** `Time_Slot`, `Semester`, and links to a specific `Professor`.
    * **Logic:** Assignments are linked here, allowing professors to customize exams per semester.

### 3. Registration & Grading Module (The Core Logic)
This is where the system handles the heavy lifting of student performance tracking.

* **`Enrollment`**
    * **Role:** The junction table linking `Student` and `Section`.
    * **Data:** Stores the `Final_Grade` (0-100) and `Letter_Grade`.
    * **Automation:** Updated automatically via Triggers when assignments are graded.

* **`Assignment`**
    * **Role:** Defines gradable items (e.g., "Midterm", "Final Project").
    * **Data:** Includes `Weight_Percent` (e.g., 40%) to allow for weighted average calculations.

* **`Student_Submission`**
    * **Role:** Records the actual score a student received.
    * **Trigger:** Inserting a score here fires the `trg_AutoUpdateFinalGradeFromAssignments`.

* **`Waitlist`**
    * **Role:** A First-In-First-Out (FIFO) queue for full sections.
    * **Automation:** If an enrolled student drops, the system automatically promotes the next student in this queue.

### 4. Financial Module
* **`Tuition_Bill`**
    * **Role:** Tracks revenue and student debt.
    * **Data:** `Total_Amount`, `Due_Date`, and `Is_Paid` status.
 
## Key Features & Functionalities

This project moves beyond simple CRUD operations by implementing a reactive, event-driven architecture directly within the database engine.

### 1. The "Chain Reaction" Grading Engine 
We implemented a multi-stage trigger system to ensure grade consistency without manual recalculation.

* **Logic:** When a Professor grades an assignment, a cascade of events occurs:
    1.  **Level 1 Trigger:** `trg_AutoUpdateFinalGradeFromAssignments` fires on the `Student_Submission` table. It recalculates the weighted average for that specific course section.
    2.  **Level 2 Trigger:** `trg_AutoUpdateGPA` fires on the `Enrollment` table. It detects the change in the course grade and immediately recalculates the student's cumulative GPA across all historical semesters.
* **Result:** The `Student.GPA` field is always 100% accurate and up-to-date in real-time.

### 2. Smart Enrollment System with Waitlists 
The system handles high-demand courses using a First-In-First-Out (FIFO) queue system, ensuring fair access to resources.

* **Prerequisite Enforcement:** The `sp_EnrollStudent` procedure utilizes the `fn_CheckPrerequisites` scalar function. It recursively checks if a student has passed required prior courses before allowing registration.
* **Automated Promotion:**
    * If a section is full, students are placed in the `Waitlist` table.
    * **Trigger:** `trg_CheckWaitlistPromotion` monitors the `Enrollment` table. If a registered student drops the class, the system *instantly* moves the first person from the Waitlist into the empty seat and notifies the admin.

### 3. Financial Lifecycle Management 
The database automates the accounts receivable process for the university.

* **Bill Generation:** `sp_GenerateTuitionBill` calculates total tuition based on the credit hours of enrolled courses.
* **Revenue Tracking:** The `View_Unpaid_Tuition` provides a real-time ledger of outstanding debts, filtering out active vs. inactive students.

### 4. Enterprise-Grade Security (RBAC) 
Security is handled at the database object layer, not just the application layer. We follow the **Principle of Least Privilege**.

| Role | Access Level | Description |
| :--- | :--- | :--- |
| **db_Admin** | `CONTROL` | Full schema access. Can Admit/Withdraw students and manage finances. |
| **db_Professor** | `EXECUTE` | Can run specific grading procedures (`sp_GradeSubmission`). **Explicitly DENIED** ability to delete Student or Course records. |
| **db_Student** | `SELECT` | Read-only access to public schedules (`View_Master_Schedule`). Cannot modify any data. |

### 5. Data Preservation (Soft Deletes) 
To maintain academic integrity and audit trails, we do not physically delete records.
* **Implementation:** The `sp_WithdrawStudent` procedure sets an `is_active` bit flag to `0`.
* **Benefit:** The student is removed from current rosters and billing cycles, but their historical transcript and GPA data remain intact for future reference.

---

## Project Structure

* `01_Delete.sql`: Cleanup script to reset the database state.
* `02_Schema.sql`: DDL for Tables and Constraints.
* `04_Procedures.sql`: Business logic encapsulation.
* `05_Trigger.sql`: Automation and reactive logic.
* `06_Views.sql`: Reporting abstraction layer.
* `07_Security.sql`: User roles and permission grants.
* `08_Seed_Data.sql`: Initial dummy data population (Students, Courses, and Assignments) to allow for immediate testing.
* `09_test.sql`: Test suite demonstrating the "Happy Path" and edge cases.

## How to Run
1.  Open **VS Code**.
2.  Execute files in numerical order (01 -> 09).
3.  Check the `Messages` tab to verify successful object creation.
4.  Run the demo scenarios in `09_test.sql` to witness the automation in action.
    * **Security:** Access is restricted to Admin roles only.

---
