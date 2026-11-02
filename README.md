# ScholarSync — Academic Course Registration & Learning Management System

> **Object-Oriented Programming System (OOPS) Capstone Project**  
> **Course / Lab:** Advanced Object-Oriented Software Engineering & Java Lab  
> **Tech Stack:** Java 17+, Spring Boot 3.3.5, Raw JDBC (HikariCP), Supabase PostgreSQL, HTML5/CSS3/Vanilla JavaScript  

---

### Student / Project Submission Details
- **Project Title:** ScholarSync: Enterprise Academic Course Registration & LMS Platform
- **Student Name:** [Your Name Here]
- **Roll Number / Student ID:** [Your Roll Number Here]
- **Department:** Department of Computer Science & Engineering
- **Semester / Section:** [Semester & Section Here]
- **Academic Year:** 2026-2027

---

## 1. Project Overview

**ScholarSync** is an enterprise-grade academic course registration and learning management platform designed and implemented using core **Object-Oriented Programming (OOP)** principles and a robust 3-tier enterprise architectural model.

The platform provides a streamlined, role-based workflow across three distinct institutional actors:
1. **Students**:
   - Browse the institutional course catalog and filter by semester, instructor, or keyword.
   - Submit formal enrollment and drop requests.
   - Access structured lesson modules (textual lectures and external video/reference resources).
   - Take interactive multiple-choice assessments with automated server-side grading.
   - Earn cryptographically verifiable digital course completion certificates.
   - Unlock gamified achievement badges and complete engagement side quests.
   - Track progress along curated career roadmaps.
2. **Administrators**:
   - Manage the institutional course catalog (create, edit, update seat capacities).
   - Author lesson content and manage course learning materials.
   - Build quiz question banks with configurable scoring and multiple options.
   - Create curated career paths linking sequenced coursework.
   - Author engagement side quests and monitor student analytics.
3. **Academic Registrars**:
   - Review pending student enrollment and course drop requests.
   - Enforce seat capacity limits using concurrency-safe database transactions.
   - Decommission retired courses while gracefully preserving student academic history.

---

## 2. Multi-Port Architecture

ScholarSync provides dedicated independent ports for each role and portal, all connecting seamlessly to the central backend REST API and cloud database:

| Portal | Port & URL | Description |
| :--- | :--- | :--- |
| **Main Gateway** | [`http://localhost:5500`](http://localhost:5500) | Central portal with unified login and student registration |
| **Student Portal** | [`http://localhost:5501`](http://localhost:5501) | Dedicated dashboard for enrolled courses, quizzes, and certificates |
| **Admin Console** | [`http://localhost:5502`](http://localhost:5502) | Management hub for courses, content, quizzes, and career tracks |
| **Registrar Portal** | [`http://localhost:5503`](http://localhost:5503) | Institutional approval queue for enrollments and course drops |
| **Certificate Verify** | [`http://localhost:5504`](http://localhost:5504) | Public cryptographic certificate verification (no login required) |
| **REST API Server** | [`http://localhost:8080/api`](http://localhost:8080/api) | High-performance Spring Boot REST API |

---

## 3. Object-Oriented Programming (OOP) Architecture

The application is structured to explicitly demonstrate the four pillars of Object-Oriented Programming alongside modern enterprise design patterns:

```
                  +-----------------------------------+
                  |         Presentation Layer        |
                  |  Vanilla JS UI / REST Controllers |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------------------------+
                  |       Service / Business Layer    |
                  | Validation, Transactions, Logic   |
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------------------------+
                  |     Data Access Object (DAO)      |
                  |  Raw JDBC PreparedStatement/Hikari|
                  +-----------------+-----------------+
                                    |
                                    v
                  +-----------------------------------+
                  |        Relational Cloud DB        |
                  |      Supabase PostgreSQL Engine   |
                  +-----------------------------------+
```

### 3.1 Encapsulation
- **Domain Records:** Immutable data carriers (`User`, `Course`, `Enrollment`, `Quiz`, `QuizQuestion`, `Certificate`) protect domain state from uncontrolled external modification.
- **Controlled State Transitions:** Seat availability and enrollment states can only be mutated via encapsulated service methods enforcing institutional business rules.

### 3.2 Abstraction
- **Separation of Concerns:** Business rules are abstracted entirely within the Service Layer (`EnrollmentService`, `CourseService`, `QuizService`), while persistence operations are isolated in specialized Data Access Objects (DAOs).
- **Driver Abstraction:** JDBC `DataSource` and `Connection` pooling via HikariCP hide raw connection handling and thread management behind clean interfaces.

### 3.3 Polymorphism & Inheritance
- **Security Principal:** `AuthenticatedUser` implements Spring Security's `UserDetails` interface, enabling polymorphic authentication across varying role authorizations.
- **Exception Hierarchy:** Custom `ApiException` extends Java's `RuntimeException`, captured and translated polymorphically into RFC-7807 compliant JSON errors by `GlobalExceptionHandler`.
- **Dynamic Achievements:** Badges are polymorphically computed on the fly through progress analysis without requiring redundant storage.

### 3.4 ACID Transactions & Pessimistic Concurrency Control
To prevent race conditions during high-volume registration periods (e.g., two students competing for the last available seat):
- Approvals run within an isolated database transaction with row-level pessimistic locking:
  ```sql
  SELECT * FROM courses WHERE id = ? FOR UPDATE;
  ```
- Re-verifies seat availability before executing seat increment, preventing overselling.
- Backed by relational check constraints: `CONSTRAINT chk_seats CHECK (seats_taken >= 0 AND seats_taken <= capacity)`.

---

## 4. Quick Start with One-Click Batch Script

The system includes a single, clean batch launcher: **`run.bat`**.

### How to Run:
1. Ensure your Supabase credentials are saved in [`.env`](.env):
   ```properties
   SUPABASE_PROJECT_REF=your_project_reference_id
   SUPABASE_DB_PASSWORD=your_database_password
   ```
2. Double-click **`run.bat`** in the project root.
3. The servers will initialize in the background, and the interactive **Control Center** will display:

```
========================================================================
                 ScholarSync: Multi-Portal Control Center
========================================================================

  ALL PORTALS CONNECTED TO CENTRAL BACKEND (http://localhost:8080/api):

    [1] Student Portal        --> http://localhost:5501
    [2] Admin Console         --> http://localhost:5502
    [3] Registrar Portal      --> http://localhost:5503
    [4] Certificate Verify    --> http://localhost:5504
    [5] Main Gateway (Login)  --> http://localhost:5500

    [A] Open ALL Portals in separate browser tabs at once

------------------------------------------------------------------------
  DEMO CREDENTIALS:
    - Admin:      admin     / admin123
    - Registrar:  registrar / registrar123
    - Student:    student   / student123  (or self-register)
------------------------------------------------------------------------
    [0] Stop All Servers and Exit
========================================================================

Select an option (0-5, A): 
```

- Type **`1`** $\rightarrow$ Opens the **Student Portal** in your browser.
- Type **`2`** $\rightarrow$ Opens the **Admin Console** in your browser.
- Type **`3`** $\rightarrow$ Opens the **Registrar Portal** in your browser.
- Type **`4`** $\rightarrow$ Opens the **Certificate Verification Page**.
- Type **`A`** $\rightarrow$ Opens **all portals** in separate browser tabs at once!
- Type **`0`** $\rightarrow$ Safely shuts down all background servers.

---

## 5. Demonstration Credentials

| Role | Username | Password | Port / Direct URL | Capabilities |
| :--- | :--- | :--- | :--- | :--- |
| **Admin** | `admin` | `admin123` | [`http://localhost:5502`](http://localhost:5502) | Manage courses, author lessons, build quizzes, create career paths |
| **Registrar** | `registrar` | `registrar123` | [`http://localhost:5503`](http://localhost:5503) | Approve/reject enrollments and drops, soft-delete courses |
| **Student** | `student` | `student123` | [`http://localhost:5501`](http://localhost:5501) | Register, view lessons, take assessments, claim certificates |

*Note: New student accounts can also be self-registered directly from the login page on Port 5500.*

---

## 6. Functional Workflow & Lifecycle

### 6.1 Course Enrollment & Drop State Machine
```
[Student Request] ──────> PENDING ───────> [Registrar Approves] ──────> APPROVED (Seat Held)
                                  │
                                  └──────> [Registrar Rejects] ───────> REJECTED

[Student Request Drop] ──> DROP_PENDING ──> [Registrar Approves] ────> DROPPED (Seat Released)
                                        │
                                        └──> [Registrar Rejects] ─────> DROP_REJECTED (Stays Enrolled)
```

### 6.2 Assessment & Certificate Issuance
1. Student accesses approved course content modules.
2. Completing required lessons unlocks course quizzes.
3. Quizzes are submitted and automatically evaluated on the server (options shuffled, correct answers withheld until post-submission review).
4. Achieving $\ge 60\%$ on all course assessments unlocks the **Verified Certificate Claim**.
5. Public verification code allows third parties to confirm certificate authenticity at Port 5504 (`/verify.html`).

---

## 7. REST API Endpoints Overview

| HTTP Method | Route | Access Level | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/login` | Public | Authenticates credentials and returns signed JWT |
| `POST` | `/api/auth/register` | Public | Self-registration for new students |
| `GET` | `/api/certificates/verify/{code}` | Public | Public cryptographic certificate verification |
| `GET` | `/api/courses` | Authenticated | Browse active courses with filter support |
| `POST` | `/api/student/enrollments` | Student | Submit course enrollment request |
| `POST` | `/api/student/enrollments/{id}/drop` | Student | Request to drop an approved course |
| `GET` | `/api/student/schedule` | Student | View current student timetable |
| `POST` | `/api/student/quizzes/{id}/submit`| Student | Submit quiz answers for auto-grading |
| `POST` | `/api/student/courses/{id}/certificate/claim` | Student | Request verified certificate upon course completion |
| `GET` | `/api/student/badges` | Student | View dynamically computed achievements |
| `GET` | `/api/registrar/enrollments/pending`| Registrar | View pending enrollment queue |
| `POST` | `/api/registrar/enrollments/{id}/approve` | Registrar | Atomically approve request and hold seat |
| `POST` | `/api/registrar/enrollments/{id}/reject` | Registrar | Reject enrollment request with remarks |
| `POST` | `/api/admin/courses` | Admin | Create new course listing |
| `POST` | `/api/admin/courses/{id}/contents`| Admin | Publish lesson module to course |
| `POST` | `/api/admin/courses/{id}/quizzes` | Admin | Create assessment with question bank |
| `GET` | `/api/admin/courses/{id}/analytics`| Admin | View class-wide student performance metrics |

---

## 8. Viva & Evaluation Key Discussion Points

1. **Why Raw JDBC instead of Spring Data JPA/Hibernate?**  
   Raw JDBC demonstrates fundamental database programming concepts: explicit transaction boundary management, custom connection lifecycle handling, fine-grained prepared statements, and direct control over lock escalation (`SELECT ... FOR UPDATE`), which are often obscured by ORM abstraction layers.
2. **How is seat overselling prevented?**  
   Using transactional pessimistic row-level locking on the `courses` record when a registrar evaluates a request, coupled with a relational `CHECK` constraint.
3. **How does the certificate verification mechanism work?**  
   Upon qualifying, a unique UUID-based hash code is issued and stored in the database. Anyone can query `/api/certificates/verify/{code}` without authentication to verify student identity, completion date, and course details.
