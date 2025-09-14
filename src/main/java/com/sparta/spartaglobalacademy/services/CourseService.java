package com.sparta.spartaglobalacademy.services;

import com.sparta.spartaglobalacademy.entities.CourseEntity;
import com.sparta.spartaglobalacademy.records.CourseMapper;
import com.sparta.spartaglobalacademy.records.CourseRecord;
import com.sparta.spartaglobalacademy.repositories.CourseRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Service
public class CourseService {

    private final CourseRepository courseRepository;
    private final CourseMapper courseMapper;

    public CourseService(CourseRepository courseRepository, CourseMapper courseMapper) {
        if (courseRepository == null) {
            throw new IllegalArgumentException("CourseRepository cannot be null");
        }
        if (courseMapper == null) {
            throw new IllegalArgumentException("CourseMapper cannot be null");
        }
        this.courseRepository = courseRepository;
        this.courseMapper = courseMapper;
    }

    // CREATE a new course with validation
    public CourseRecord createCourse(CourseEntity course) {
        validateCourse(course);
        CourseEntity saved = courseRepository.save(course);
        return courseMapper.toRecord(saved);
    }

    // READ: get all courses
    public List<CourseRecord> getAllCourses() {
        List<CourseEntity> entities = courseRepository.findAll();
        ArrayList<CourseRecord> results = new ArrayList<>();
        for (CourseEntity e : entities) {
            results.add(courseMapper.toRecord(e));
        }
        return results;
    }

    // READ: get course by ID
    public CourseRecord getCourseById(Integer id) {
        CourseEntity entity = courseRepository.findById(id).orElse(null);
        if (entity == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Course not found with ID: " + id);
        }
        return courseMapper.toRecord(entity);
    }

    // UPDATE: update existing course with validation
    public CourseRecord updateCourse(Integer id, CourseEntity updatedCourse) {
        if (id == null || updatedCourse == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Course ID and entity cannot be null");
        }

        CourseEntity existing = courseRepository.findById(id).orElse(null);
        if (existing == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Course not found with ID: " + id);
        }

        validateCourse(updatedCourse);

        // Update fields
        existing.setTitle(updatedCourse.getTitle());
        existing.setDescription(updatedCourse.getDescription());
        existing.setEnrollDate(updatedCourse.getEnrollDate());
        existing.setTrainer(updatedCourse.getTrainer());

        CourseEntity saved = courseRepository.save(existing);
        return courseMapper.toRecord(saved);
    }

    // DELETE: delete a course (return boolean)
    public boolean deleteCourse(Integer id) {
        if (courseRepository.existsById(id)) {
            courseRepository.deleteById(id);
            return true;
        }
        return false;
    }

    // Utility: validate course fields
    private void validateCourse(CourseEntity course) {
        if (course == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Course cannot be null");
        }
        if (course.getTitle() == null || course.getTitle().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Course title cannot be empty");
        }
        if (course.getDescription() == null || course.getDescription().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Course description cannot be empty");
        }
        if (course.getEnrollDate() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Enroll date cannot be null");
        }
        if (course.getEnrollDate().isBefore(LocalDate.now())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Enroll date cannot be in the past");
        }
        if (course.getTrainer() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Course must have a trainer assigned");
        }
    }
}
