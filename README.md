# University Management Database System

## Project Overview
This repository contains the complete MSSQL database implementation for a **University Management System**. The project was designed to streamline academic operations, focusing on data integrity, automated business logic, and a scalable relational schema.

## Key Features
* **Advanced Schema Design:** Implemented an inheritance-based model for specialized entities (Students, Instructors, and Staff) stemming from a central Person table.
* **Automated Business Logic:** * **Triggers:** Automated validation for course prerequisites and enrollment capacity.
    * **Stored Procedures:** Simplified complex operations such as registering students and generating academic transcripts.
* **Relational Integrity:** Strict use of Primary Keys, Foreign Keys, and Check Constraints to ensure data consistency.
* **Financial Tracking:** Built-in logic for managing tuition fees, billing, and payment history.

## Technologies Used
* **Database:** Microsoft SQL Server (MSSQL)
* **Development Environment:** Visual Studio Code
* **Language:** T-SQL
