package com.sparta.spartaglobalacademy.controllers;

import com.sparta.spartaglobalacademy.entities.CourseEntity;
import com.sparta.spartaglobalacademy.records.CourseRecord;
import com.sparta.spartaglobalacademy.records.CourseMapper;
import com.sparta.spartaglobalacademy.services.CourseService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import org.springframework.validation.annotation.Validated;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/courses")
@Validated
public class CourseController {

    private final CourseService courseService;
    private final CourseMapper courseMapper;

    public CourseController(CourseService courseService, CourseMapper courseMapper) {
        this.courseService = courseService;
        this.courseMapper = courseMapper;
    }

    // CREATE: POST /courses
    @Operation(summary = "Create a new course", description = "Add a new course to the system")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Course created",
                    content = @Content(schema = @Schema(implementation = CourseRecord.class))),
            @ApiResponse(responseCode = "400", description = "Invalid input", content = @Content)
    })
    @PostMapping
    public ResponseEntity<CourseRecord> createCourse(@Valid @RequestBody CourseRecord courseRecord) {
        CourseEntity toCreate = courseMapper.toEntity(courseRecord);
        CourseRecord created = courseService.createCourse(toCreate);
        return ResponseEntity.ok(created);
    }

    // READ: GET /courses
    @Operation(summary = "Get all courses", description = "Retrieve a list of all courses")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "List of courses",
                    content = @Content(array = @ArraySchema(schema = @Schema(implementation = CourseRecord.class))))
    })
    @GetMapping
    public ResponseEntity<List<CourseRecord>> getAllCourses() {
        List<CourseRecord> records = courseService.getAllCourses();
        return ResponseEntity.ok(records);
    }

    // READ: GET /courses/{id}
    @Operation(summary = "Get a course by ID", description = "Retrieve a single course by its ID")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Course found",
                    content = @Content(schema = @Schema(implementation = CourseRecord.class))),
            @ApiResponse(responseCode = "404", description = "Course not found", content = @Content)
    })
    @GetMapping("/{id}")
    public ResponseEntity<CourseRecord> getCourseById(@Min(1) @PathVariable Integer id) {
        CourseRecord course = courseService.getCourseById(id);
        return ResponseEntity.ok(course);
    }

    // UPDATE: PUT /courses/{id}
    @Operation(summary = "Update a course", description = "Update an existing course by ID")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Course updated",
                    content = @Content(schema = @Schema(implementation = CourseRecord.class))),
            @ApiResponse(responseCode = "400", description = "Invalid input", content = @Content),
            @ApiResponse(responseCode = "404", description = "Course not found", content = @Content)
    })
    @PutMapping("/{id}")
    public ResponseEntity<CourseRecord> updateCourse(
            @Min(1) @PathVariable Integer id,
            @Valid @RequestBody CourseRecord courseRecord
    ) {
        CourseRecord updated = courseService.updateCourse(id, courseMapper.toEntity(courseRecord));
        return ResponseEntity.ok(updated);
    }

    // DELETE: DELETE /courses/{id}
    @Operation(summary = "Delete a course", description = "Delete a course by ID")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Course deleted", content = @Content),
            @ApiResponse(responseCode = "404", description = "Course not found", content = @Content)
    })
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCourse(@Min(1) @PathVariable Integer id) {
        boolean deleted = courseService.deleteCourse(id);
        return deleted ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }
}
