-- ===============================================
-- Sparta Academy — Seed Data Restore Procedure
-- Restores canonical seed data without dropping schema
-- Usage (from mysql client):
--   SOURCE src/main/resources/database_restore_proc.sql;
--   CALL sp_restore_seed_data();
-- ===============================================

USE sparta_academy;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_restore_seed_data $$

CREATE PROCEDURE sp_restore_seed_data()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Ensure base tables exist (no-op if already present)
    CREATE TABLE IF NOT EXISTS trainers (
        trainer_id INT PRIMARY KEY AUTO_INCREMENT,
        full_name VARCHAR(100) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

        CONSTRAINT chk_trainer_name_not_empty CHECK (CHAR_LENGTH(TRIM(full_name)) > 0),
        INDEX idx_trainer_name (full_name)
    ) ENGINE=InnoDB CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    COMMENT='Sparta Academy trainers/instructors';

    CREATE TABLE IF NOT EXISTS courses (
        course_id INT PRIMARY KEY AUTO_INCREMENT,
        title VARCHAR(50) NOT NULL,
        description TEXT NOT NULL,
        enroll_date DATE NOT NULL,
        trainer_id INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

        CONSTRAINT fk_courses_trainer 
            FOREIGN KEY (trainer_id) 
            REFERENCES trainers(trainer_id) 
            ON DELETE RESTRICT 
            ON UPDATE CASCADE,

        CONSTRAINT chk_course_title_not_empty CHECK (CHAR_LENGTH(TRIM(title)) > 0),
        CONSTRAINT chk_course_description_not_empty CHECK (CHAR_LENGTH(TRIM(description)) > 0),
        CONSTRAINT chk_course_enroll_date_valid CHECK (enroll_date >= '2020-01-01'),

        INDEX idx_course_title (title),
        INDEX idx_course_enroll_date (enroll_date),
        INDEX idx_course_trainer (trainer_id)
    ) ENGINE=InnoDB CHARACTER SET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    COMMENT='Sparta Academy courses and training programs';

    -- Upsert canonical trainers
    INSERT INTO trainers (trainer_id, full_name)
    VALUES
        (1, 'Phil Windridge'),
        (2, 'Catherine French'),
        (3, 'Nish Mandal'), 
        (4, 'Abdul Shahrukh Khan'),
        (5, 'Paula Savaglia')
    ON DUPLICATE KEY UPDATE
        full_name = VALUES(full_name);

    -- Upsert canonical courses
    INSERT INTO courses (course_id, title, description, enroll_date, trainer_id)
    VALUES
        (1, 'TECH 300', 'C# Development Course', '2023-03-01', 1),
        (2, 'TECH 301', 'Java Development Course', '2023-04-01', 2),
        (3, 'TECH 302', 'C# Testing Course', '2023-05-01', 3),
        (4, 'TECH 303', 'DevOps Engineering Course', '2023-06-01', 4),
        (5, 'DATA 304', 'Data Science Course', '2023-07-01', 5)
    ON DUPLICATE KEY UPDATE
        title = VALUES(title),
        description = VALUES(description),
        enroll_date = VALUES(enroll_date),
        trainer_id = VALUES(trainer_id);

    -- Recreate/refresh view
    CREATE OR REPLACE VIEW course_details AS
    SELECT 
        c.course_id,
        c.title AS course_title,
        c.description AS course_description,
        c.enroll_date,
        t.trainer_id,
        t.full_name AS trainer_name,
        DATEDIFF(CURDATE(), c.enroll_date) AS days_since_enrollment
    FROM courses c
    INNER JOIN trainers t ON c.trainer_id = t.trainer_id;

    COMMIT;
END $$

DELIMITER ;

-- To execute immediately after sourcing this file:
-- CALL sp_restore_seed_data();

