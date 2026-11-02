# Academic Course Registration System (ScholarSync)
## Software Requirements & System Extension Specification

**Project Type:** Object-Oriented Programming System (OOPS) Course Project  
**Architecture:** 3-Tier Layered Architecture (REST Controller, Service Business Logic, JDBC DAO, Relational Database)  
**Security Model:** Role-Based Access Control (RBAC) via Stateless JWT  

---

## 1. System Overview & Core Capabilities

The Course Registration and Academic Management System (`ScholarSync`) provides an enterprise-grade platform managing the full academic lifecycle across three primary user roles:
1. **Students**: Browse available course catalogs, request enrollments and course drops, track academic progress, take automated assessment quizzes, complete course side quests, earn verifiable certificates, and track career learning paths.
2. **Administrators**: Manage the course catalog, lesson modules, quiz assessments with question banks, gamified engagement quests, and structured career paths.
3. **Registrars**: Act as the institutional authority for academic approvals, handling pending enrollment and drop requests with transaction-safe seat allocation, and managing course decommissioning.

---

## 2. Object-Oriented Design (OOP) Principles Applied

### 2.1 Encapsulation
- Immutable record representations for core domain entities (`User`, `Course`, `Enrollment`, `Quiz`, `QuizQuestion`, `Certificate`).
- All state modification is strictly mediated through service methods encapsulating business rules and invariants (e.g., seat capacity bounds, status transition state machines).

### 2.2 Abstraction
- The presentation layer (REST Controllers) is completely decoupled from the data access layer (DAOs).
- Data access is abstracted using the Data Access Object (DAO) pattern with raw JDBC, avoiding ORM overhead while retaining complete control over SQL statements and transaction isolation levels.

### 2.3 Polymorphic Role-Based Access
- Single user principal (`AuthenticatedUser`) implements Spring Security's `UserDetails` contract.
- Role-based authorization policies (`ROLE_STUDENT`, `ROLE_ADMIN`, `ROLE_REGISTRAR`) polymorphically govern endpoint accessibility and system privileges.

### 2.4 High Cohesion & Loose Coupling
- Independent service modules for each functional domain: `EnrollmentService`, `CourseService`, `QuizService`, `CertificateService`, `BadgeService`, `CareerPathService`, and `SideQuestService`.
- Shared cross-cutting concerns (authentication, JWT parsing, exception translation) are centralized in dedicated security filters and global exception handlers.

---

## 3. Concurrency Control & ACID Transaction Guarantees

In competitive course registration scenarios, multiple students may attempt to enroll in limited-capacity courses simultaneously.
- **Seat Allocation Safety:** Implemented using pessimistic locking (`SELECT ... FOR UPDATE`) in MySQL within `EnrollmentService.approveEnrollment`.
- **Database Invariant:** Enforced at the relational level via `CHECK (seats_taken >= 0 AND seats_taken <= capacity)`.
- **Atomic Operations:** Registrars' enrollment approval runs inside a managed transaction context ensuring seat count increments and status updates succeed or fail as a single atomic unit.

---

## 4. Planned Architectural Extensions: Feature 01 — Course Prerequisites

### 4.1 Objective
Enable administrators to define directed prerequisite dependencies between courses, automatically validating student eligibility during the enrollment request pipeline to prevent registration in advanced courses without foundational coursework.

### 4.2 Database Schema Extension
```sql
CREATE TABLE IF NOT EXISTS course_prerequisites (
    id                     BIGINT AUTO_INCREMENT PRIMARY KEY,
    course_id              BIGINT NOT NULL,
    prerequisite_course_id BIGINT NOT NULL,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_cp_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    CONSTRAINT fk_cp_prereq FOREIGN KEY (prerequisite_course_id) REFERENCES courses(id) ON DELETE RESTRICT,
    CONSTRAINT uq_course_prereq UNIQUE (course_id, prerequisite_course_id),
    CONSTRAINT chk_no_self_prereq CHECK (course_id <> prerequisite_course_id)
) ENGINE=InnoDB;
```

### 4.3 Validation Logic & Graph Cycle Prevention
1. **Cycle Detection:** Perform Depth-First Search (DFS) / topological traversal across prerequisite relations prior to saving to prevent circular dependencies (e.g., Course A -> Course B -> Course A).
2. **Self-Prerequisite Prevention:** Blocked via both database check constraint `chk_no_self_prereq` and service-layer validation.

### 4.4 Student Enrollment Pipeline Verification
When a student initiates an enrollment request for course `C`:
1. Query `course_prerequisites` for all required prerequisite course IDs.
2. Cross-reference the student's completed coursework (`enrollments` with `status = 'APPROVED'` and `certificates` issued or passing grades).
3. If unmet prerequisites exist:
   - Reject request with HTTP 409 Conflict.
   - Return structured payload indicating missing requirements:
   ```json
   {
     "eligible": false,
     "missingPrerequisites": [
       "CS101: Introduction to Programming",
       "MA150: Discrete Mathematics"
     ]
   }
   ```
4. If all prerequisites are satisfied, proceed to standard seat-check and pending request registration.
