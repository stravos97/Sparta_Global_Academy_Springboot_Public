package com.sparta.spartaglobalacademy.services;

import com.sparta.spartaglobalacademy.entities.CourseEntity;
import com.sparta.spartaglobalacademy.entities.TrainerEntity;
import com.sparta.spartaglobalacademy.records.CourseMapper;
import com.sparta.spartaglobalacademy.records.CourseRecord;
import com.sparta.spartaglobalacademy.repositories.CourseRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;
import org.springframework.web.server.ResponseStatusException;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class CourseServiceTest {

    private CourseRepository courseRepository;
    private CourseService courseService;
    private CourseMapper courseMapper;

    @BeforeEach
    void setUp() {
        courseRepository = mock(CourseRepository.class);
        courseMapper = mock(CourseMapper.class);
        courseService = new CourseService(courseRepository, courseMapper);
    }

    //HAPPY Path - CREATE

    @Test
    @DisplayName("create course should save course when valid")
    void testCreateCourseValid() {
        TrainerEntity trainer = new TrainerEntity();
        trainer.setId(1);
        trainer.setFullName("Trainer1");

        CourseEntity course = new CourseEntity();
        course.setTitle("Java Basics");
        course.setDescription("Intro to Java");
        course.setEnrollDate(LocalDate.now().plusDays(5));
        course.setTrainer(trainer);

        when(courseRepository.save(course)).thenReturn(course);
        when(courseMapper.toRecord(course)).thenReturn(
                new CourseRecord(null, "Java Basics", "Intro to Java", course.getEnrollDate(), trainer.getId())
        );

        CourseRecord saved = courseService.createCourse(course);

        assertNotNull(saved);
        assertEquals("Java Basics", saved.title());
        assertEquals(1, saved.trainerId());
        verify(courseRepository, times(1)).save(course);
    }

    // Sad path - Create
    @Test
    @DisplayName("createCourse should throw 400 if title is blank")
    void testCreateCourseInvalidTitle() {
        TrainerEntity trainer = new TrainerEntity();
        trainer.setId(1);
        trainer.setFullName("Trainer1");

        CourseEntity course = new CourseEntity();
        course.setTitle(""); // invalid
        course.setDescription("Intro to Java");
        course.setEnrollDate(LocalDate.now().plusDays(5));
        course.setTrainer(trainer);

        ResponseStatusException ex = assertThrows(ResponseStatusException.class,
                () -> courseService.createCourse(course));
        assertEquals(400, ex.getStatusCode().value());
    }

    //SAD PATH 2 - Create

    @Test
    @DisplayName("createCourse should throw 400 if enrollDate is in past")
    void testCreateCoursePastDate() {
        TrainerEntity trainer = new TrainerEntity();
        trainer.setId(1);
        trainer.setFullName("Trainer1");

        CourseEntity course = new CourseEntity();
        course.setTitle("Java Basics");
        course.setDescription("Intro to Java");
        course.setEnrollDate(LocalDate.now().minusDays(1)); // invalid
        course.setTrainer(trainer);

        ResponseStatusException ex = assertThrows(ResponseStatusException.class,
                () -> courseService.createCourse(course));
        assertEquals(400, ex.getStatusCode().value());
    }

    // Happy path  - READ get all

    @Test
    @DisplayName("getAllCourses should return list")
    void testGetAllCourses() {
        TrainerEntity trainer = new TrainerEntity();
        trainer.setId(1);
        trainer.setFullName("Trainer1");

        CourseEntity c1 = new CourseEntity();
        c1.setTitle("Spring Boot");
        c1.setDescription("Learn Spring");
        c1.setEnrollDate(LocalDate.now().plusDays(10));
        c1.setTrainer(trainer);

        when(courseRepository.findAll()).thenReturn(List.of(c1));
        when(courseMapper.toRecord(c1)).thenReturn(
                new CourseRecord(null, "Spring Boot", "Learn Spring", c1.getEnrollDate(), trainer.getId())
        );

        List<CourseRecord> result = courseService.getAllCourses();

        assertEquals(1, result.size());
        assertEquals("Spring Boot", result.get(0).title());
    }

    // Happy path getCourseID
    @Test
    @DisplayName("getCourseById should return course if found")
    void testGetCourseByIdFound() {
        TrainerEntity trainer = new TrainerEntity();
        trainer.setId(1);
        trainer.setFullName("Trainer1");

        CourseEntity course = new CourseEntity();
        course.setTitle("Java Basics");
        course.setDescription("Intro to Java");
        course.setEnrollDate(LocalDate.now().plusDays(5));
        course.setTrainer(trainer);

        when(courseRepository.findById(1)).thenReturn(Optional.of(course));
        when(courseMapper.toRecord(course)).thenReturn(
                new CourseRecord(null, "Java Basics", "Intro to Java", course.getEnrollDate(), trainer.getId())
        );

        CourseRecord result = courseService.getCourseById(1);

        assertEquals("Java Basics", result.title());
        assertEquals(1, result.trainerId());
    }

    // Sad Path getCourseby Id
    @Test
    @DisplayName("getCourseById should throw 404 if not found")
    void testGetCourseByIdNotFound() {
        when(courseRepository.findById(1)).thenReturn(Optional.empty());

        ResponseStatusException ex = assertThrows(ResponseStatusException.class,
                () -> courseService.getCourseById(1));
        assertEquals(404, ex.getStatusCode().value());
    }

    //  Happy Path - UPDATE

    @Test
    @DisplayName("updateCourse should update and save course")
    void testUpdateCourse() {
        TrainerEntity trainerOld = new TrainerEntity();
        trainerOld.setId(1);
        trainerOld.setFullName("Trainer1");

        TrainerEntity trainerNew = new TrainerEntity();
        trainerNew.setId(2);
        trainerNew.setFullName("Trainer2");

        CourseEntity existing = new CourseEntity();
        existing.setTitle("Old Title");
        existing.setDescription("Old desc");
        existing.setEnrollDate(LocalDate.now().plusDays(5));
        existing.setTrainer(trainerOld);

        CourseEntity updated = new CourseEntity();
        updated.setTitle("New Title");
        updated.setDescription("New desc");
        updated.setEnrollDate(LocalDate.now().plusDays(10));
        updated.setTrainer(trainerNew);

        when(courseRepository.findById(1)).thenReturn(Optional.of(existing));
        when(courseRepository.save(existing)).thenReturn(existing);
        when(courseMapper.toRecord(existing)).thenReturn(
                new CourseRecord(null, "New Title", "New desc", updated.getEnrollDate(), trainerNew.getId())
        );

        CourseRecord result = courseService.updateCourse(1, updated);

        assertEquals("New Title", result.title());
        assertEquals("New desc", result.description());
        assertEquals(2, result.trainerId());
    }
    // Sad Path
    @Test
    @DisplayName("updateCourse should throw when course does not exist")
    void testUpdateCourseNotFound() {
        CourseEntity updated = new CourseEntity();
        updated.setTitle("New Title");
        updated.setDescription("New desc");
        updated.setEnrollDate(LocalDate.now().plusDays(10));

        when(courseRepository.findById(99)).thenReturn(Optional.empty());

        // Act & Assert
        ResponseStatusException ex = assertThrows(ResponseStatusException.class,
                () -> courseService.updateCourse(99, updated));
        assertEquals(404, ex.getStatusCode().value());
    }


    //  Happy Path - DELETE

    @Test
    @DisplayName("deleteCourse should return true and delete when exists")
    void testDeleteCourseExists() {
        when(courseRepository.existsById(1)).thenReturn(true);
        doNothing().when(courseRepository).deleteById(1);

        boolean result = courseService.deleteCourse(1);

        assertTrue(result);
        verify(courseRepository, times(1)).deleteById(1);
    }

    // Sad path - delete
    @Test
    @DisplayName("deleteCourse should return false when not exists")
    void testDeleteCourseNotExists() {
        when(courseRepository.existsById(1)).thenReturn(false);

        boolean result = courseService.deleteCourse(1);

        assertFalse(result);
        verify(courseRepository, never()).deleteById(anyInt());
    }
}
