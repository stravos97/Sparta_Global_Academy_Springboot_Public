package com.sparta.spartaglobalacademy.records;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.LocalDate;

@Schema(name = "Course", description = "Record for Course")
public record CourseRecord(
        @Schema(description = "Course ID", example = "1")
        Integer id,

        @Schema(description = "Title of the course", example = "Java Basics")
        String title,

        @Schema(description = "Short description of the course", example = "Intro to Java")
        String description,

        @Schema(description = "Enrollment date", example = "2025-01-15")
        LocalDate enrollDate,

        @Schema(description = "Trainer ID for this course", example = "2")
        Integer trainerId
) {}

