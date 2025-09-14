package com.sparta.spartaglobalacademy.repositories;

import com.sparta.spartaglobalacademy.entities.CourseEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface CourseRepository extends JpaRepository<CourseEntity, Integer> {
    List<CourseEntity> findByTrainerId(Integer trainerId);
    List<CourseEntity> findByTitleContaining(String title);
    List<CourseEntity> findByDescriptionContaining(String description);
    List<CourseEntity> findByTrainerIdAndEnrollDateAfter(Integer trainerId, LocalDate enrollDate);
    long countByTrainerId(Integer trainerId);
    boolean existsByTitleIgnoreCase(String title);
}
