-- =====================================================================
-- ScholarSync: Academic Course Registration & Management System
-- Database Initialization Script for Supabase PostgreSQL
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Table: users
-- Core entity representing students, administrators, and registrar.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id            BIGSERIAL PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    role          VARCHAR(20)  NOT NULL CHECK (role IN ('STUDENT', 'ADMIN', 'REGISTRAR')),
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- 2. Table: courses
-- Academic course offerings with seat capacity and status.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS courses (
    id               BIGSERIAL PRIMARY KEY,
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
    status           VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'REMOVED')),
    created_at       TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_seats CHECK (seats_taken >= 0 AND seats_taken <= capacity)
);

-- ---------------------------------------------------------------------
-- 3. Table: course_prerequisites
-- Defines prerequisite rules between academic courses.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS course_prerequisites (
    id                     BIGSERIAL PRIMARY KEY,
    course_id              BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    prerequisite_course_id BIGINT NOT NULL REFERENCES courses(id) ON DELETE RESTRICT,
    created_at             TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_course_prereq UNIQUE (course_id, prerequisite_course_id),
    CONSTRAINT chk_no_self_prereq CHECK (course_id <> prerequisite_course_id)
);

-- ---------------------------------------------------------------------
-- 4. Table: enrollments
-- Registration lifecycle: PENDING -> APPROVED / REJECTED -> DROP_PENDING -> DROPPED
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS enrollments (
    id            BIGSERIAL PRIMARY KEY,
    student_id    BIGINT NOT NULL REFERENCES users(id),
    course_id     BIGINT NOT NULL REFERENCES courses(id),
    status        VARCHAR(20) NOT NULL DEFAULT 'PENDING' 
                  CHECK (status IN ('PENDING','APPROVED','REJECTED','DROP_PENDING','DROPPED','DROP_REJECTED')),
    requested_at  TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    decided_at    TIMESTAMP WITHOUT TIME ZONE NULL,
    decided_by    BIGINT NULL REFERENCES users(id),
    remarks       VARCHAR(255)
);

-- ---------------------------------------------------------------------
-- 5. Table: course_contents
-- Learning resources (textual lessons and external references) per course.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS course_contents (
    id            BIGSERIAL PRIMARY KEY,
    course_id     BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    title         VARCHAR(150) NOT NULL,
    content_type  VARCHAR(10) NOT NULL DEFAULT 'TEXT' CHECK (content_type IN ('TEXT', 'LINK')),
    body          TEXT,
    external_url  VARCHAR(500),
    order_index   INT NOT NULL DEFAULT 0,
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- 6. Table: quizzes & quiz_questions & quiz_options
-- Online assessment system with automated grading.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS quizzes (
    id           BIGSERIAL PRIMARY KEY,
    course_id    BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    title        VARCHAR(150) NOT NULL,
    description  TEXT,
    created_at   TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS quiz_questions (
    id             BIGSERIAL PRIMARY KEY,
    quiz_id        BIGINT NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
    question_text  TEXT NOT NULL,
    order_index    INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS quiz_options (
    id             BIGSERIAL PRIMARY KEY,
    question_id    BIGINT NOT NULL REFERENCES quiz_questions(id) ON DELETE CASCADE,
    option_text    VARCHAR(500) NOT NULL,
    is_correct     BOOLEAN NOT NULL DEFAULT FALSE,
    order_index    INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS quiz_attempts (
    id                BIGSERIAL PRIMARY KEY,
    quiz_id           BIGINT NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
    student_id        BIGINT NOT NULL REFERENCES users(id),
    score             INT NOT NULL,
    total_questions   INT NOT NULL,
    submitted_at      TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS quiz_attempt_answers (
    id                   BIGSERIAL PRIMARY KEY,
    attempt_id           BIGINT NOT NULL REFERENCES quiz_attempts(id) ON DELETE CASCADE,
    question_id          BIGINT NOT NULL REFERENCES quiz_questions(id),
    selected_option_id   BIGINT NULL REFERENCES quiz_options(id),
    was_correct          BOOLEAN NOT NULL DEFAULT FALSE
);

-- ---------------------------------------------------------------------
-- 7. Table: content_progress & certificates
-- Student learning progress tracking and verifiable digital credentials.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS content_progress (
    student_id    BIGINT NOT NULL REFERENCES users(id),
    content_id    BIGINT NOT NULL REFERENCES course_contents(id) ON DELETE CASCADE,
    completed_at  TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (student_id, content_id)
);

CREATE TABLE IF NOT EXISTS certificates (
    id                 BIGSERIAL PRIMARY KEY,
    student_id         BIGINT NOT NULL REFERENCES users(id),
    course_id          BIGINT NOT NULL REFERENCES courses(id),
    certificate_code   VARCHAR(40) NOT NULL UNIQUE,
    issued_at          TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_cert_student_course UNIQUE (student_id, course_id)
);

-- ---------------------------------------------------------------------
-- 8. Table: career_paths & career_path_courses
-- Structured learning curriculums toward specific career outcomes.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS career_paths (
    id           BIGSERIAL PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    description  TEXT,
    created_at   TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS career_path_courses (
    career_path_id  BIGINT NOT NULL REFERENCES career_paths(id) ON DELETE CASCADE,
    course_id       BIGINT NOT NULL REFERENCES courses(id),
    order_index     INT NOT NULL DEFAULT 0,

    PRIMARY KEY (career_path_id, course_id)
);

-- ---------------------------------------------------------------------
-- 9. Table: side_quests & side_quest_completions
-- Interactive gamification tasks designed for course engagement.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS side_quests (
    id           BIGSERIAL PRIMARY KEY,
    course_id    BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    title        VARCHAR(150) NOT NULL,
    description  TEXT,
    points       INT NOT NULL DEFAULT 10,
    created_at   TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS side_quest_completions (
    student_id     BIGINT NOT NULL REFERENCES users(id),
    quest_id       BIGINT NOT NULL REFERENCES side_quests(id) ON DELETE CASCADE,
    completed_at   TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (student_id, quest_id)
);

-- ---------------------------------------------------------------------
-- Indexes for query performance
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
-- Seed Initial Demo Accounts (BCrypt encrypted)
-- Admin: admin / admin123
-- Registrar: registrar / registrar123
-- Student: student / student123
-- ---------------------------------------------------------------------
INSERT INTO users (username, password_hash, full_name, email, role) VALUES
('admin',     '$2b$10$5pEaUqNWtblwQAdjfWtE3uD25xTAHDMj/.3WsPWmVtvhqImdk/WAG', 'System Administrator', 'admin@campus.edu',     'ADMIN'),
('registrar', '$2b$10$tGufdRV0MIyFcDWybU3Icu03xwTRLeU210vpbURXLcvd2Ngbc/Ssa', 'Academic Registrar',  'registrar@campus.edu', 'REGISTRAR'),
('student',   '$2b$10$tGufdRV0MIyFcDWybU3Icu03xwTRLeU210vpbURXLcvd2Ngbc/Ssa', 'John Doe',             'student@campus.edu',   'STUDENT')
ON CONFLICT (username) DO UPDATE SET full_name = EXCLUDED.full_name;

-- ---------------------------------------------------------------------
-- Seed Sample Academic Courses
-- ---------------------------------------------------------------------
INSERT INTO courses (id, code, title, description, credits, instructor_name, day_of_week, start_time, end_time, semester, capacity) VALUES
(1, 'CS101', 'Introduction to Programming', 'Fundamentals of programming using Java: variables, control flow, OOP basics.', 4, 'Dr. A. Sharma',   'MONDAY',    '09:00:00', '10:30:00', 'Fall 2026', 30),
(2, 'CS201', 'Data Structures & Algorithms', 'Arrays, lists, trees, graphs, sorting/searching, and complexity analysis.',    4, 'Dr. R. Verma',    'TUESDAY',   '11:00:00', '12:30:00', 'Fall 2026', 25),
(3, 'MA150', 'Discrete Mathematics',        'Logic, set theory, combinatorics, and graph theory for CS students.',        3, 'Prof. K. Iyer',   'WEDNESDAY', '13:00:00', '14:00:00', 'Fall 2026', 30),
(4, 'CS310', 'Database Systems',            'Relational model, SQL, normalization, transactions, and indexing.',         4, 'Dr. S. Rao',      'THURSDAY',  '10:00:00', '11:30:00', 'Fall 2026', 25),
(5, 'CS405', 'Web Application Development', 'Full-stack web development: REST APIs, auth, and modern JS frontends.',     3, 'Dr. A. Sharma',   'FRIDAY',    '09:00:00', '10:30:00', 'Fall 2026', 30)
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title;

SELECT setval(pg_get_serial_sequence('courses', 'id'), (SELECT MAX(id) FROM courses));

-- ---------------------------------------------------------------------
-- Seed Course Contents
-- ---------------------------------------------------------------------
INSERT INTO course_contents (course_id, title, content_type, body, external_url, order_index) VALUES
(1, 'Course Introduction & Environment Setup', 'TEXT', 'Welcome to CS101! Make sure you have JDK 17+ installed alongside your preferred IDE (IntelliJ IDEA, Eclipse, or VS Code).', NULL, 1),
(1, 'Object-Oriented Programming Fundamentals', 'TEXT', 'Understanding Classes, Objects, Methods, Encapsulation, and Constructors in Java.', NULL, 2),
(1, 'Official Java Documentation', 'LINK', NULL, 'https://docs.oracle.com/en/java/', 3),
(2, 'Linear Data Structures Overview', 'TEXT', 'Deep dive into memory layouts of Arrays, Linked Lists, Stacks, and Queues.', NULL, 1)
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------
-- Seed Career Paths
-- ---------------------------------------------------------------------
INSERT INTO career_paths (id, name, description) VALUES
(1, 'Software Engineering Track', 'Comprehensive progression from programming fundamentals to database systems and web applications.')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO career_path_courses (career_path_id, course_id, order_index) VALUES
(1, 1, 1),
(1, 2, 2),
(1, 4, 3),
(1, 5, 4)
ON CONFLICT (career_path_id, course_id) DO UPDATE SET order_index = EXCLUDED.order_index;

SELECT setval(pg_get_serial_sequence('career_paths', 'id'), (SELECT MAX(id) FROM career_paths));

-- ---------------------------------------------------------------------
-- 10. Enable Row Level Security (RLS) on all public tables
-- Secures tables against unauthorized direct browser/PostgREST queries.
-- Backend JDBC (postgres user) bypasses RLS safely.
-- ---------------------------------------------------------------------
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_prerequisites ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_contents ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempt_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE career_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE career_path_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE side_quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE side_quest_completions ENABLE ROW LEVEL SECURITY;