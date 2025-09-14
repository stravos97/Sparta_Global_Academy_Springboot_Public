package com.sparta.spartaglobalacademy.controllers;

import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/db")
public class DbController {

    private final JdbcTemplate jdbcTemplate;

    public DbController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/ping")
    public ResponseEntity<String> ping() {
        Integer one = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
        return ResponseEntity.ok("OK: " + one);
    }

    @GetMapping("/tables")
    public List<String> listTables() {
        String sql = "SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE() ORDER BY table_name";
        return jdbcTemplate.queryForList(sql, String.class);
    }

    public enum SampleTable {
        trainers,
        courses,
        course_details
    }

    @GetMapping("/sample")
    public List<Map<String, Object>> sample(@RequestParam("table") SampleTable table) {
        // Avoid SQL injection: do not concatenate user input into SQL.
        // Use an enum whitelist and choose a constant SQL string per value.
        final String sql;
        switch (table) {
            case trainers -> sql = "SELECT trainer_id, full_name, created_at, updated_at FROM trainers LIMIT 10";
            case courses -> sql = "SELECT course_id, title, description, enroll_date, trainer_id, created_at, updated_at FROM courses LIMIT 10";
            case course_details -> sql = "SELECT course_id, course_title, course_description, enroll_date, trainer_id, trainer_name, days_since_enrollment FROM course_details LIMIT 10";
            default -> throw new IllegalArgumentException("Unsupported table");
        }
        return jdbcTemplate.queryForList(sql);
    }
}
