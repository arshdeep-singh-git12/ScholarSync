-- =====================================================================
-- ScholarSync: Academic Course Registration & Management System
-- Database Initialization Script (Full Schema + Seed Data)
-- Subject: Object-Oriented Programming System (OOPS) Project
-- =====================================================================

CREATE DATABASE IF NOT EXISTS course_registration
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE course_registration;

-- ---------------------------------------------------------------------
-- 1. Table: users
-- Core entity representing students, administrators, and registrar.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    role          ENUM('STUDENT', 'ADMIN', 'REGISTRAR') NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. Table: courses
-- Academic course offerings with seat capacity and lifecycle status.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS courses (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    code             VARCHAR(20)  NOT NULL UNIQUE,
    title            VARCHAR(150) NOT NULL,
    description      TEXT,
    credits          INT NOT NULL DEFAULT 3,
    instructor_name  VARCHAR(100) NOT NULL,
    day_of_week      VARCHAR(15)  NOT NULL,
    start_time       TIME NOT NULL,
    end_time         TIME NOT NULL,
    semester         VARCHAR(30)  NOT NULL,
    capacity         INT NOT NULL,
    seats_taken      INT NOT NULL DEFAULT 0,
    status           ENUM('ACTIVE', 'REMOVED') NOT NULL DEFAULT 'ACTIVE',
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_seats CHECK (seats_taken >= 0 AND seats_taken <= capacity)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. Table: course_prerequisites
-- Defines prerequisite rules between academic courses.
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- 4. Table: enrollments
-- Registration lifecycle: PENDING -> APPROVED / REJECTED -> DROP_PENDING -> DROPPED
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS enrollments (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id    BIGINT NOT NULL,
    course_id     BIGINT NOT NULL,
    status        ENUM('PENDING','APPROVED','REJECTED','DROP_PENDING','DROPPED','DROP_REJECTED')
                  NOT NULL DEFAULT 'PENDING',
    requested_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    decided_at    TIMESTAMP NULL,
    decided_by    BIGINT NULL,
    remarks       VARCHAR(255),

    CONSTRAINT fk_enroll_student FOREIGN KEY (student_id) REFERENCES users(id),
    CONSTRAINT fk_enroll_course  FOREIGN KEY (course_id)  REFERENCES courses(id),
    CONSTRAINT fk_enroll_decider FOREIGN KEY (decided_by) REFERENCES users(id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. Table: course_contents
-- Learning resources (textual lessons and external references) per course.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS course_contents (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    course_id     BIGINT NOT NULL,
    title         VARCHAR(150) NOT NULL,
    content_type  ENUM('TEXT', 'LINK') NOT NULL DEFAULT 'TEXT',
    body          TEXT,
    external_url  VARCHAR(500),
    order_index   INT NOT NULL DEFAULT 0,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_content_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. Table: quizzes & quiz_questions & quiz_options
-- Online assessment system with automated grading.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS quizzes (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    course_id    BIGINT NOT NULL,
    title        VARCHAR(150) NOT NULL,
    description  TEXT,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_quiz_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS quiz_questions (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    quiz_id        BIGINT NOT NULL,
    question_text  TEXT NOT NULL,
    order_index    INT NOT NULL DEFAULT 0,

    CONSTRAINT fk_question_quiz FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS quiz_options (
    id             BIGINT AUTO_INCREMENT PRIMARY KEY,
    question_id    BIGINT NOT NULL,
    option_text    VARCHAR(500) NOT NULL,
    is_correct     BOOLEAN NOT NULL DEFAULT FALSE,
    order_index    INT NOT NULL DEFAULT 0,

    CONSTRAINT fk_option_question FOREIGN KEY (question_id) REFERENCES quiz_questions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS quiz_attempts (
    id                BIGINT AUTO_INCREMENT PRIMARY KEY,
    quiz_id           BIGINT NOT NULL,
    student_id        BIGINT NOT NULL,
    score             INT NOT NULL,
    total_questions   INT NOT NULL,
    submitted_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_attempt_quiz FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE,
    CONSTRAINT fk_attempt_student FOREIGN KEY (student_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS quiz_attempt_answers (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    attempt_id           BIGINT NOT NULL,
    question_id          BIGINT NOT NULL,
    selected_option_id   BIGINT NULL,
    was_correct          BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT fk_answer_attempt  FOREIGN KEY (attempt_id) REFERENCES quiz_attempts(id) ON DELETE CASCADE,
    CONSTRAINT fk_answer_question FOREIGN KEY (question_id) REFERENCES quiz_questions(id),
    CONSTRAINT fk_answer_option   FOREIGN KEY (selected_option_id) REFERENCES quiz_options(id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. Table: content_progress & certificates
-- Student learning progress tracking and verifiable digital credentials.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS content_progress (
    student_id    BIGINT NOT NULL,
    content_id    BIGINT NOT NULL,
    completed_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (student_id, content_id),
    CONSTRAINT fk_progress_student FOREIGN KEY (student_id) REFERENCES users(id),
    CONSTRAINT fk_progress_content FOREIGN KEY (content_id) REFERENCES course_contents(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS certificates (
    id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
    student_id         BIGINT NOT NULL,
    course_id          BIGINT NOT NULL,
    certificate_code   VARCHAR(40) NOT NULL UNIQUE,
    issued_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_cert_student_course UNIQUE (student_id, course_id),
    CONSTRAINT fk_cert_student FOREIGN KEY (student_id) REFERENCES users(id),
    CONSTRAINT fk_cert_course FOREIGN KEY (course_id) REFERENCES courses(id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. Table: career_paths & career_path_courses
-- Structured learning curriculums toward specific career outcomes.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS career_paths (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    description  TEXT,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS career_path_courses (
    career_path_id  BIGINT NOT NULL,
    course_id       BIGINT NOT NULL,
    order_index     INT NOT NULL DEFAULT 0,

    PRIMARY KEY (career_path_id, course_id),
    CONSTRAINT fk_pathcourse_path   FOREIGN KEY (career_path_id) REFERENCES career_paths(id) ON DELETE CASCADE,
    CONSTRAINT fk_pathcourse_course FOREIGN KEY (course_id) REFERENCES courses(id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. Table: side_quests & side_quest_completions
-- Interactive gamification tasks designed for course engagement.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS side_quests (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    course_id    BIGINT NOT NULL,
    title        VARCHAR(150) NOT NULL,
    description  TEXT,
    points       INT NOT NULL DEFAULT 10,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_quest_course FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS side_quest_completions (
    student_id     BIGINT NOT NULL,
    quest_id       BIGINT NOT NULL,
    completed_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (student_id, quest_id),
    CONSTRAINT fk_qc_student FOREIGN KEY (student_id) REFERENCES users(id),
    CONSTRAINT fk_qc_quest   FOREIGN KEY (quest_id) REFERENCES side_quests(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Indexes for query optimization
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_enrollments_student ON enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course  ON enrollments(course_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_status  ON enrollments(status);
CREATE INDEX IF NOT EXISTS idx_courses_status      ON courses(status);
CREATE INDEX IF NOT EXISTS idx_content_course      ON course_contents(course_id);
CREATE INDEX IF NOT EXISTS idx_quiz_course         ON quizzes(course_id);
CREATE INDEX IF NOT EXISTS idx_question_quiz       ON quiz_questions(quiz_id);
CREATE INDEX IF NOT EXISTS idx_option_question     ON quiz_options(question_id);
CREATE INDEX IF NOT EXISTS idx_attempt_quiz_student ON quiz_attempts(quiz_id, student_id);
CREATE INDEX IF NOT EXISTS idx_answer_attempt      ON quiz_attempt_answers(attempt_id);
CREATE INDEX IF NOT EXISTS idx_progress_student_content ON content_progress(student_id, content_id);
CREATE INDEX IF NOT EXISTS idx_cert_code           ON certificates(certificate_code);
CREATE INDEX IF NOT EXISTS idx_quest_course        ON side_quests(course_id);

-- ---------------------------------------------------------------------
-- Seed Initial Users (BCrypt encrypted passwords)
-- Admin: admin / admin123
-- Registrar: registrar / registrar123
-- Student: student / student123
-- ---------------------------------------------------------------------
INSERT INTO users (username, password_hash, full_name, email, role) VALUES
('admin',     '$2b$10$5pEaUqNWtblwQAdjfWtE3uD25xTAHDMj/.3WsPWmVtvhqImdk/WAG', 'System Administrator', 'admin@campus.edu',     'ADMIN'),
('registrar', '$2b$10$tGufdRV0MIyFcDWybU3Icu03xwTRLeU210vpbURXLcvd2Ngbc/Ssa', 'Academic Registrar',  'registrar@campus.edu', 'REGISTRAR'),
('student',   '$2b$10$tGufdRV0MIyFcDWybU3Icu03xwTRLeU210vpbURXLcvd2Ngbc/Ssa', 'John Doe',             'student@campus.edu',   'STUDENT')
ON DUPLICATE KEY UPDATE full_name = VALUES(full_name);

-- ---------------------------------------------------------------------
-- Seed Sample Academic Courses
-- ---------------------------------------------------------------------
INSERT INTO courses (code, title, description, credits, instructor_name, day_of_week, start_time, end_time, semester, capacity) VALUES
('CS101', 'Introduction to Programming', 'Fundamentals of programming using Java: variables, control flow, OOP basics.', 4, 'Dr. A. Sharma',   'MONDAY',    '09:00:00', '10:30:00', 'Fall 2026', 30),
('CS201', 'Data Structures & Algorithms', 'Arrays, lists, trees, graphs, sorting/searching, and complexity analysis.',    4, 'Dr. R. Verma',    'TUESDAY',   '11:00:00', '12:30:00', 'Fall 2026', 25),
('MA150', 'Discrete Mathematics',        'Logic, set theory, combinatorics, and graph theory for CS students.',        3, 'Prof. K. Iyer',   'WEDNESDAY', '13:00:00', '14:00:00', 'Fall 2026', 30),
('CS310', 'Database Systems',            'Relational model, SQL, normalization, transactions, and indexing.',         4, 'Dr. S. Rao',      'THURSDAY',  '10:00:00', '11:30:00', 'Fall 2026', 25),
('CS405', 'Web Application Development', 'Full-stack web development: REST APIs, auth, and modern JS frontends.',     3, 'Dr. A. Sharma',   'FRIDAY',    '09:00:00', '10:30:00', 'Fall 2026', 30)
ON DUPLICATE KEY UPDATE title = VALUES(title);

-- ---------------------------------------------------------------------
-- Seed Course Contents
-- ---------------------------------------------------------------------
INSERT INTO course_contents (course_id, title, content_type, body, external_url, order_index) VALUES
(1, 'Course Introduction & Environment Setup', 'TEXT', 'Welcome to CS101! Make sure you have JDK 17+ installed alongside your preferred IDE (IntelliJ IDEA, Eclipse, or VS Code).', NULL, 1),
(1, 'Object-Oriented Programming Fundamentals', 'TEXT', 'Understanding Classes, Objects, Methods, Encapsulation, and Constructors in Java.', NULL, 2),
(1, 'Official Java Documentation', 'LINK', NULL, 'https://docs.oracle.com/en/java/', 3),
(2, 'Linear Data Structures Overview', 'TEXT', 'Deep dive into memory layouts of Arrays, Linked Lists, Stacks, and Queues.', NULL, 1)
ON DUPLICATE KEY UPDATE title = VALUES(title);

-- ---------------------------------------------------------------------
-- Seed Career Paths
-- ---------------------------------------------------------------------
INSERT INTO career_paths (id, name, description) VALUES
(1, 'Software Engineering Track', 'Comprehensive progression from programming fundamentals to database systems and web applications.')
ON DUPLICATE KEY UPDATE name = VALUES(name);

INSERT INTO career_path_courses (career_path_id, course_id, order_index) VALUES
(1, 1, 1),
(1, 2, 2),
(1, 4, 3),
(1, 5, 4)
ON DUPLICATE KEY UPDATE order_index = VALUES(order_index);
