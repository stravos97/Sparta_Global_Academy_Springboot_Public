-- ===============================================
-- Sparta Academy — Quick Reseed Script
-- Fast reset to canonical data (drops data only)
-- Safe to run repeatedly; does not drop schema
-- ===============================================

USE sparta_academy;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE courses;
TRUNCATE TABLE trainers;
SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO trainers (trainer_id, full_name) VALUES
(1, 'Phil Windridge'),
(2, 'Catherine French'),
(3, 'Nish Mandal'), 
(4, 'Abdul Shahrukh Khan'),
(5, 'Paula Savaglia');

INSERT INTO courses (course_id, title, description, enroll_date, trainer_id) VALUES
(1, 'TECH 300', 'C# Development Course', '2023-03-01', 1),
(2, 'TECH 301', 'Java Development Course', '2023-04-01', 2),
(3, 'TECH 302', 'C# Testing Course', '2023-05-01', 3),
(4, 'TECH 303', 'DevOps Engineering Course', '2023-06-01', 4),
(5, 'DATA 304', 'Data Science Course', '2023-07-01', 5);

-- Refresh view (no-op if already exists)
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

