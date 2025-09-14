-- ===============================================
-- Sparta Academy Database Setup Script (FIXED)
-- ===============================================
-- Creates tables and inserts trainer/course data
-- Run this after server_setup.sh completes
-- ===============================================

-- Ensure we're using the correct database
USE sparta_academy;

-- Enable foreign key checks
SET foreign_key_checks = 1;

-- ===============================================
-- DROP EXISTING TABLES (if they exist)
-- ===============================================
DROP TABLE IF EXISTS courses;
DROP TABLE IF EXISTS trainers;

-- ===============================================
-- CREATE TRAINERS TABLE
-- ===============================================
CREATE TABLE trainers (
    trainer_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_trainer_name_not_empty CHECK (CHAR_LENGTH(TRIM(full_name)) > 0),
    
    -- Indexes
    INDEX idx_trainer_name (full_name)
) ENGINE=InnoDB CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Sparta Academy trainers/instructors';

-- ===============================================
-- CREATE COURSES TABLE  
-- ===============================================
CREATE TABLE courses (
    course_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    enroll_date DATE NOT NULL,
    trainer_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key constraint
    CONSTRAINT fk_courses_trainer 
        FOREIGN KEY (trainer_id) 
        REFERENCES trainers(trainer_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_course_title_not_empty CHECK (CHAR_LENGTH(TRIM(title)) > 0),
    CONSTRAINT chk_course_description_not_empty CHECK (CHAR_LENGTH(TRIM(description)) > 0),
    CONSTRAINT chk_course_enroll_date_valid CHECK (enroll_date >= '2020-01-01'),
    
    -- Indexes
    INDEX idx_course_title (title),
    INDEX idx_course_enroll_date (enroll_date),
    INDEX idx_course_trainer (trainer_id)
) ENGINE=InnoDB CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Sparta Academy courses and training programs';

-- ===============================================
-- INSERT TRAINER DATA
-- ===============================================
INSERT INTO trainers (trainer_id, full_name) VALUES
(1, 'Phil Windridge'),
(2, 'Catherine French'),
(3, 'Nish Mandal'), 
(4, 'Abdul Shahrukh Khan'),
(5, 'Paula Savaglia');

-- ===============================================
-- INSERT COURSE DATA
-- ===============================================
INSERT INTO courses (course_id, title, description, enroll_date, trainer_id) VALUES
(1, 'TECH 300', 'C# Development Course', '2023-03-01', 1),
(2, 'TECH 301', 'Java Development Course', '2023-04-01', 2),
(3, 'TECH 302', 'C# Testing Course', '2023-05-01', 3),
(4, 'TECH 303', 'DevOps Engineering Course', '2023-06-01', 4),
(5, 'DATA 304', 'Data Science Course', '2023-07-01', 5);

-- ===============================================
-- CREATE USEFUL VIEW
-- ===============================================
CREATE OR REPLACE VIEW course_details AS
SELECT 
    c.course_id,
    c.title as course_title,
    c.description as course_description,
    c.enroll_date,
    t.trainer_id,
    t.full_name as trainer_name,
    DATEDIFF(CURDATE(), c.enroll_date) as days_since_enrollment
FROM courses c
INNER JOIN trainers t ON c.trainer_id = t.trainer_id;

-- ===============================================
-- VERIFICATION QUERIES
-- ===============================================

-- Count records in each table
SELECT 'trainers' as table_name, COUNT(*) as record_count FROM trainers
UNION ALL
SELECT 'courses' as table_name, COUNT(*) as record_count FROM courses;

-- Show all trainers
SELECT trainer_id, full_name, created_at FROM trainers ORDER BY trainer_id;

-- Show all courses with trainer names
SELECT 
    c.course_id,
    c.title,
    c.description,
    c.enroll_date,
    t.full_name as trainer_name,
    c.created_at
FROM courses c
INNER JOIN trainers t ON c.trainer_id = t.trainer_id
ORDER BY c.enroll_date;

-- Show courses by trainer summary
SELECT 
    t.full_name as trainer,
    COUNT(c.course_id) as total_courses,
    GROUP_CONCAT(c.title ORDER BY c.enroll_date SEPARATOR ', ') as courses_taught,
    MIN(c.enroll_date) as first_course_date,
    MAX(c.enroll_date) as latest_course_date
FROM trainers t
LEFT JOIN courses c ON t.trainer_id = c.trainer_id
GROUP BY t.trainer_id, t.full_name
ORDER BY total_courses DESC, t.full_name;

-- Test the course_details view
SELECT * FROM course_details ORDER BY enroll_date;

-- ===============================================
-- PERFORMANCE OPTIMIZATION
-- ===============================================
ANALYZE TABLE trainers, courses;

-- Show final table information
SELECT 
    table_name,
    table_rows,
    data_length,
    index_length,
    table_comment
FROM information_schema.tables 
WHERE table_schema = 'sparta_academy' AND table_type = 'BASE TABLE'
ORDER BY table_name;