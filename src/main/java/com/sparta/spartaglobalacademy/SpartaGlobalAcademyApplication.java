package com.sparta.spartaglobalacademy;

import com.sparta.spartaglobalacademy.entities.CourseEntity;
import com.sparta.spartaglobalacademy.entities.TrainerEntity;
import com.sparta.spartaglobalacademy.repositories.CourseRepository;
import com.sparta.spartaglobalacademy.repositories.TrainerRepository;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;

import java.util.List;

// accessible on http://localhost:8091/swagger-ui/index.html

@SpringBootApplication
public class SpartaGlobalAcademyApplication {
    public static void main(String[] args) {
        SpringApplication.run(SpartaGlobalAcademyApplication.class, args);
    }
}
