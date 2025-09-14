Sparta Global Academy — IntelliJ IDEA MySQL Setup

Overview
- Connect IntelliJ IDEA Database tool to the remote MySQL used by this app.
- Quick copy/paste values below + troubleshooting and verification steps.

Connection Settings
- Host: <remote-host>
- Port: 3306
- User: sparta_user (or value from `DB_USERNAME`)
- Password: from `DB_PASSWORD` (not committed)
- Database: sparta_academy
- URL: jdbc:mysql://<remote-host>:3306/sparta_academy

Step‑by‑Step in IntelliJ
1) Open Database tool window: View → Tool Windows → Database
2) Add datasource: + → Data Source → MySQL
3) Enter Host, Port, User, Password, Database from above
4) Driver: click “Download” if prompted to download the MySQL driver
5) Optional: Advanced → Options (only if needed)
   - Add connection properties for edge cases:
     - useSSL=false
     - allowPublicKeyRetrieval=true
     - serverTimezone=UTC
   - Example URL if adding options:
     jdbc:mysql://<remote-host>:3306/sparta_academy?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
6) Click “Test Connection”
7) Click “OK” if the test succeeds

Verify Connection (in IntelliJ)
- Expand the datasource → Schemas → sparta_academy → Tables
- You should see tables: trainers, courses, and view: course_details
- Run quick queries:
  - SELECT COUNT(*) FROM trainers;
  - SELECT COUNT(*) FROM courses;
  - SELECT * FROM course_details LIMIT 10;

Populate/Repair Database (optional)
- If tables are missing or empty, run this script on the server:
  - File: src/main/resources/database_setup_fixed.sql
  - It creates tables and inserts sample data for trainers and courses.

App Configuration (Spring Boot)
- The app defaults `DB_URL` to this MySQL instance; provide credentials at runtime via env vars:
  - DB_URL (default: jdbc:mysql://<remote-host>:3306/sparta_academy)
  - DB_USERNAME (required)
  - DB_PASSWORD (required)

Local Verification via REST Endpoints
- Start app: mvn spring-boot:run (port 8091)
- Check connectivity:
  - GET http://localhost:8091/db/ping → OK: 1
  - GET http://localhost:8091/db/tables → lists DB tables
  - GET http://localhost:8091/db/sample?table=courses → first 10 rows

Recovery / Reseed Options
- Quick reseed data only (keeps schema):
  1) mysql -h <remote-host> -P 3306 -u sparta_user -p sparta_academy < src/main/resources/database_reseed_quick.sql
  2) Verify with: SELECT COUNT(*) FROM trainers; SELECT COUNT(*) FROM courses;
- Idempotent restore procedure (no drops, upserts rows):
  1) mysql -h <remote-host> -P 3306 -u sparta_user -p sparta_academy < src/main/resources/database_restore_proc.sql
  2) mysql -h <remote-host> -P 3306 -u sparta_user -p -e "CALL sparta_academy.sp_restore_seed_data();"
- Full rebuild (drops/creates tables, recreates view, repopulates):
  1) mysql -h <remote-host> -P 3306 -u sparta_user -p sparta_academy < src/main/resources/database_setup_fixed.sql
  2) This is the most thorough if schema got corrupted.

Troubleshooting
- Connection refused or timeout:
  - Ensure firewall allows inbound TCP 3306 to your server IP
  - Confirm MySQL is running on the server
  - Verify user has remote privileges for sparta_user@'%'
- Authentication errors:
  - Re-enter exact password shown above
  - Try Options: allowPublicKeyRetrieval=true
- SSL or timezone warnings:
  - Try Options: useSSL=false, serverTimezone=UTC
- Schema missing:
  - Run: src/main/resources/database_setup_fixed.sql against sparta_academy

Security Notes
- The password is included here to expedite setup. Rotate it later and switch to environment variables for local development.

Inline SQL — Quick Reseed Script
Use when schema is intact but data needs to be reset to the canonical seed set. Safe to run repeatedly.

```sql
-- Sparta Academy — Quick Reseed Script
-- Fast reset to canonical data (drops data only)
-- Safe to run repeatedly; does not drop schema

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
```

Inline SQL — Restore Procedure (Idempotent)
Use when you want a safe, transactional restore that upserts rows and recreates the view without dropping schema.

```sql
-- Sparta Academy — Seed Data Restore Procedure
-- Restores canonical seed data without dropping schema
-- Usage (from mysql client):
--   CALL sparta_academy.sp_restore_seed_data();

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
```

Inline Execution Examples
- Quick reseed:
  - In IntelliJ DB console: paste the “Quick Reseed Script” block and run all.
  - CLI: mysql -h <remote-host> -P 3306 -u sparta_user -p sparta_academy < src/main/resources/database_reseed_quick.sql
- Restore procedure:
  - In IntelliJ DB console: paste the “Restore Procedure” block, run it to define the procedure, then execute: CALL sparta_academy.sp_restore_seed_data();
  - CLI: mysql -h <remote-host> -P 3306 -u sparta_user -p -e "CALL sparta_academy.sp_restore_seed_data();"

***

Security reminders:
✓ Use environment variables or GitHub Secrets for credentials
✓ Application user should have least privilege on sparta_academy
✓ Rotate credentials periodically and never commit them to version control
