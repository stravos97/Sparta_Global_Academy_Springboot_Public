# Spring Boot API Architecture Plan

This document outlines a recommended layered architecture for the Sparta Global Academy REST API. This structure promotes a clean separation of concerns, making the application easier to develop, test, and maintain.

### 1. High-Level Overview

We will use a classic three-layer architecture. This pattern separates the application into distinct layers, each with a specific responsibility.

**Request Flow:** A client's HTTP request will flow through these layers sequentially.

`Client (Browser/Postman)` -> `Controller` -> `Service` -> `Repository` -> `Database`

**Diagram of Layers:**

```
+-------------------------------------------------------------+
|                     PRESENTATION LAYER                      |
|-------------------------------------------------------------|
|          Controllers (e.g., TrainerController)              |
|   - Defines REST endpoints (/trainers, /courses)            |
|   - Handles HTTP requests and responses                     |
|   - Uses DTOs for the API contract                          |
+-------------------------------------------------------------+
                           ^
                           | (DTOs)
                           v
+-------------------------------------------------------------+
|                      BUSINESS LOGIC LAYER                     |
|-------------------------------------------------------------|
|            Services (e.g., TrainerService)                  |
|   - Contains the core application logic                     |
|   - Orchestrates calls to repositories                      |
|   - Handles transactions                                    |
|   - Maps between DTOs and Entities                          |
+-------------------------------------------------------------+
                           ^
                           | (Entities)
                           v
+-------------------------------------------------------------+
|                       DATA ACCESS LAYER                     |
|-------------------------------------------------------------|
|          Repositories (e.g., TrainerRepository)             |
|   - Communicates directly with the database                 |
|   - Abstracts data access using Spring Data JPA             |
|   - Works exclusively with JPA Entities                     |
+-------------------------------------------------------------+
```

### 2. Component Breakdown

#### a. Controllers (Presentation Layer)

- **Responsibility:** To be the entry point for all API requests. They handle incoming HTTP requests, validate input (if necessary), and delegate the actual work to the service layer.
    
- **Example (`TrainerController.java`):**
    
    - Defines endpoints like `@GetMapping("/trainers")`, `@PostMapping("/trainers")`.
        
    - Accepts `TrainerDTO` objects in request bodies.
        
    - Calls methods on the `TrainerService`.
        
    - Returns `ResponseEntity<TrainerDTO>` or `ResponseEntity<List<TrainerDTO>>`.
        

#### b. Services (Business Logic Layer)

- **Responsibility:** To execute business logic. This is the core of the application. It's where you'll implement the logic from your user stories.
    
- **Example (`TrainerService.java`):**
    
    - Contains methods like `getAllTrainers()`, `createTrainer(TrainerDTO trainerDto)`.
        
    - Uses a `TrainerMapper` to convert the incoming DTO to a `Trainer` entity.
        
    - Calls the `TrainerRepository` to save or retrieve data.
        
    - Performs any necessary validation or data manipulation.
        
    - Maps the result from the repository back to a DTO before returning it to the controller.
        

#### c. Repositories (Data Access Layer)

- **Responsibility:** To handle all communication with the database. You'll use Spring Data JPA interfaces, which provide standard CRUD operations out of the box.
    
- **Example (`TrainerRepository.java`):**
    
    - Will be an interface: `public interface TrainerRepository extends JpaRepository<Trainer, Long>`.
        
    - Spring automatically implements methods like `findAll()`, `findById()`, `save()`, `deleteById()`.
        

#### d. Domain Models (Entities)

- **Responsibility:** To represent the data structures in your database. These are POJOs (Plain Old Java Objects) annotated with JPA annotations (`@Entity`, `@Table`, `@Id`, etc.).
    
- **Example (`Trainer.java`):**
    
    - Annotated with `@Entity`.
        
    - Has fields like `id`, `fullName`.
        
    - Defines a `@OneToOne` relationship with `Course`.
        

#### e. Records (API Contracts)

- Responsibility: Define the JSON contract for your API using Java records. Records decouple the API from internal entities.
  
- Example (`TrainerRecord.java`):
  - A Java record with fields you want to expose (e.g., `fullName`).
  - Omits sensitive/internal fields from the `Trainer` entity.
        

#### f. Mappers

- Responsibility: Convert between Entities and Records using MapStruct.
  
- Example (`TrainerMapper.java`):
  - Interface annotated with `@Mapper`.
  - Defines methods like `TrainerEntity toEntity(TrainerRecord record)` and `TrainerRecord toRecord(TrainerEntity entity)`.
  - MapStruct generates the implementation at compile time.
        

### 3. Suggested Package Structure

Organizing your code into packages based on these layers is a best practice.

```
com.sparta.spartaglobalacademy
├── controllers
│   ├── TrainerController.java
│   └── CourseController.java
├── records
│   ├── TrainerRecord.java
│   └── CourseRecord.java
├── mappers
│   ├── TrainerMapper.java
│   └── CourseMapper.java
├── models
│   ├── Trainer.java
│   └── Course.java
├── repositories
│   ├── TrainerRepository.java
│   └── CourseRepository.java
├── services
│   ├── TrainerService.java
│   └── CourseService.java
└── SpartaGlobalAcademyApplication.java
```

### 4. Database Schema and Relationships

Based on the project requirements, we have two core tables: `Trainers` and `Courses`. The relationship between them is one-to-one.

#### Entity-Relationship Diagram (ERD)

This diagram shows the logical connections between the data tables.

```
+----------------+       +---------------------+
|    TRAINERS    |       |       COURSES       |
|----------------|--(1:1)-|---------------------|
| trainer_id (PK)|       | course_id (PK)      |
| full_name      |       | title               |
+----------------+       | description         |
                         | enroll_date         |
                         | trainer_id (FK, UQ) |
                         +---------------------+
```

#### Relationship Explanation:

- Trainers and Courses (One-to-Many):
  - A single trainer can be assigned to many courses.
  - Each course is taught by exactly one trainer.
  - Implemented via `courses.trainer_id` foreign key referencing `trainers.trainer_id`.
