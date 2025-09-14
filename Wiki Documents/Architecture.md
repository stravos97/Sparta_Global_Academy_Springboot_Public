# Spring Boot API Architecture: Clean Design Patterns in Practice

## Introduction

This presentation explores the architecture of the Sparta Global Academy API, highlighting the strategic design choices that create a maintainable, scalable, and well-documented RESTful service. Rather than showing every implementation detail, we'll focus on the why behind key decisions and how they solve real-world challenges.

---

## 1. Architectural Foundation: The Layered Approach

### The Clean Separation Pattern

```
Client → Controller → Service → Repository → Database
```

**Why this matters:** Each layer has a single responsibility, creating clear boundaries that improve testability, maintainability, and team collaboration.

### Layer Responsibilities at a Glance

| Layer | Responsibility | Key Characteristics |
|-------|----------------|---------------------|
| **Controller** | HTTP interface | Thin, DTO-focused, validation enforcement |
| **Service** | Business logic | Transaction boundaries, validation, orchestration |
| **Repository** | Data access | Spring Data JPA interfaces, query methods |
| **Entities** | Domain model | JPA-mapped classes, relationship management |

**Golden Rule:** Never let repositories leak into controllers. Services are the gatekeepers of business logic.

---

## 2. Domain Modeling: Entities with Purpose

### Strategic Entity Design Choices

```java
@Entity
@Table(name = "trainers", schema = "sparta_academy", 
       indexes = @Index(name = "idx_trainer_name", columnList = "full_name"))
public class TrainerEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer trainerId;
    
    @Column(name = "full_name", nullable = false, length = 100)
    @NotNull
    @Size(max = 100)
    private String fullName;
    
    @ColumnDefault("CURRENT_TIMESTAMP")
    private LocalDateTime createdAt;
    
    @OneToMany(mappedBy = "trainer")
    @JsonManagedReference
    private List<CourseEntity> courses = new ArrayList<>();
}
```

**Why these choices?**

- **Explicit schema mapping:** `@Table(schema = "sparta_academy")` keeps database coupling visible and intentional
- **Validation at multiple levels:** Bean Validation (`@NotNull`, `@Size`) works with both API contracts and database constraints
- **Smart timestamp management:** `@ColumnDefault("CURRENT_TIMESTAMP")` delegates to database for consistency
- **Relationship handling:**
    - `@ManyToOne(fetch = FetchType.LAZY)` prevents unnecessary data loading
    - `@JsonManagedReference`/`@JsonBackReference` eliminates serialization issues

---

## 3. API Contracts: Records as DTOs

### The Power of Java Records for APIs

```java
public record TrainerRecord(
    @Schema(description = "Unique identifier for the trainer", example = "1")
    Integer trainerId,
    
    @Schema(description = "Full name of the trainer", example = "John Doe")
    @NotNull
    @Size(max = 100)
    String fullName,
    
    @Schema(description = "Date and time when trainer was created")
    LocalDateTime createdAt
) {}
```

**Benefits of this approach:**

- **Immutability by design** - No accidental state changes
- **Concise syntax** - 80% less code than traditional DTO classes
- **OpenAPI integration** - `@Schema` annotations create rich Swagger documentation
- **Clear API contracts** - Only expose what clients need

---

## 4. Mapping Strategy: MapStruct for Clean Translation

### Why MapStruct Instead of Manual Mapping?

```java
@Mapper(componentModel = "spring")
public interface TrainerMapper {
    TrainerRecord toRecord(TrainerEntity entity);
    TrainerEntity toEntity(TrainerRecord record);
    
    @Mapping(target = "trainerId", source = "trainer.trainerId")
    CourseRecord toRecord(CourseEntity entity);
}
```

**Key advantages:**

- **Zero boilerplate** - No manual field-by-field mapping code
- **Type-safe** - Compile-time validation of mappings
- **Performance** - Generated code is as efficient as hand-written
- **Testable** - Mappers can be tested in isolation

**Best Practice:** Mapping happens in the service layer, keeping controllers focused on HTTP concerns.

---

## 5. Controller Design: Thin and Focused

### What Makes a Good Controller?

```java
@RestController
@RequestMapping("/trainers")
@Validated
public class TrainerController {
    
    private final TrainerService trainerService;
    
    @GetMapping
    @Operation(summary = "List all trainers")
    public ResponseEntity<List<TrainerRecord>> getAllTrainers() {
        return ResponseEntity.ok(trainerService.getAllTrainers());
    }
    
    @PostMapping
    @Operation(summary = "Create a new trainer")
    public ResponseEntity<TrainerRecord> createTrainer(
            @RequestBody @Valid TrainerRecord trainerRecord) {
        TrainerRecord created = trainerService.createTrainer(trainerRecord);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(created);
    }
}
```

**Controller Best Practices:**

- **Thin implementation** - No business logic, just HTTP concerns
- **Validation at the edge** - `@Valid` catches invalid requests early
- **OpenAPI documentation** - `@Operation` and `@ApiResponses` create rich Swagger documentation
- **Proper status codes** - 200/201/204/404 based on operation outcomes

---

## 6. Service Layer: Where Business Logic Lives

### Why Services Are the Heart of Your Application

```java
@Service
@Transactional
public class TrainerService {
    
    private final TrainerRepository trainerRepository;
    private final TrainerMapper trainerMapper;
    
    public TrainerService(TrainerRepository trainerRepository, 
                         TrainerMapper trainerMapper) {
        this.trainerRepository = trainerRepository;
        this.trainerMapper = trainerMapper;
    }
    
    public TrainerRecord createTrainer(TrainerRecord trainerRecord) {
        // Business logic validation
        if (trainerRepository.existsByFullName(trainerRecord.fullName())) {
            throw new ResponseStatusException(
                HttpStatus.BAD_REQUEST, 
                "Trainer with this name already exists"
            );
        }
        
        TrainerEntity entity = trainerMapper.toEntity(trainerRecord);
        TrainerEntity saved = trainerRepository.save(entity);
        return trainerMapper.toRecord(saved);
    }
    
    public List<TrainerRecord> getAllTrainers() {
        return trainerRepository.findAll().stream()
            .map(trainerMapper::toRecord)
            .collect(Collectors.toList());
    }
}
```

**Service Layer Principles:**

- **Transaction management** - `@Transactional` ensures data consistency
- **Business validation** - Reject invalid operations before they reach the database
- **DTO mapping** - All entity-to-DTO conversion happens here
- **Error handling** - `ResponseStatusException` drives HTTP responses
- **Repository coordination** - Services can call multiple repositories for complex operations

---

## 7. Repository Layer: Data Access Made Simple

### What Makes a Good Repository?

```java
@Repository
public interface TrainerRepository extends JpaRepository<TrainerEntity, Integer> {
    
    boolean existsByFullName(String fullName);
    
    @Query("SELECT t FROM TrainerEntity t WHERE t.createdAt > :date")
    List<TrainerEntity> findTrainersCreatedAfter(@Param("date") LocalDateTime date);
}
```

**Repository Best Practices:**

- **Minimal implementation** - Extend Spring Data JPA interfaces
- **Derived queries** - `existsByFullName` shows clean method naming
- **Custom queries when needed** - `@Query` for complex operations
- **No business logic** - Pure data access concerns only

---

## 8. DTO Mapping: Why Services Handle Conversion

### The Critical Layering Decision

When building REST APIs with Spring Boot, a common question arises: where should DTO conversion happen?

**The answer:** In the service layer.

**Why not in the controller?**

- Controllers should remain thin and focused on HTTP concerns
- DTO conversion is part of business logic flow
- Services need to work with entities internally for complex operations
- Keeping conversion in services maintains clean layer separation

**Example of proper separation:**

```java
// Controller (no mapping)
@GetMapping("/{id}")
public ResponseEntity<TrainerRecord> getTrainer(@PathVariable Integer id) {
    return ResponseEntity.ok(trainerService.getTrainerById(id));
}

// Service (handles mapping)
public TrainerRecord getTrainerById(Integer id) {
    TrainerEntity entity = trainerRepository.findById(id)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    return trainerMapper.toRecord(entity);
}
```

---

## 9. Database Design: Alignment with Application Architecture

### Schema Considerations

- **Table structure** directly maps to entity design
- **Foreign keys** enforce data integrity (e.g., `ON DELETE RESTRICT`)
- **Indexes** align with common query patterns
- **Constraints** provide defense in depth beyond application validation

### Key Schema Features

- **One-to-Many relationships** (Trainer → Courses)
- **Audit fields** (`created_at`, `updated_at`) with database defaults
- **Validation constraints** (non-empty fields, date sanity checks)
- **Covering indexes** for performance-critical queries

---

## 10. Testing Strategy: Focus on Business Logic

### Service Layer Testing Approach

```java
@ExtendWith(MockitoExtension.class)
class TrainerServiceTest {
    
    @Mock
    private TrainerRepository trainerRepository;
    
    @Mock
    private TrainerMapper trainerMapper;
    
    @InjectMocks
    private TrainerService trainerService;
    
    @Test
    void createTrainer_validData_returnsTrainerRecord() {
        // Given
        TrainerRecord record = new TrainerRecord(null, "John Doe", null);
        TrainerEntity entity = new TrainerEntity();
        entity.setTrainerId(1);
        entity.setFullName("John Doe");
        
        when(trainerRepository.existsByFullName("John Doe")).thenReturn(false);
        when(trainerMapper.toEntity(record)).thenReturn(entity);
        when(trainerRepository.save(entity)).thenReturn(entity);
        when(trainerMapper.toRecord(entity)).thenReturn(record);
        
        // When
        TrainerRecord result = trainerService.createTrainer(record);
        
        // Then
        assertEquals("John Doe", result.fullName());
        verify(trainerRepository, times(1)).save(entity);
    }
    
    @Test
    void createTrainer_duplicateName_throwsException() {
        // Given
        TrainerRecord record = new TrainerRecord(null, "John Doe", null);
        when(trainerRepository.existsByFullName("John Doe")).thenReturn(true);
        
        // When & Then
        assertThrows(ResponseStatusException.class, () -> 
            trainerService.createTrainer(record));
    }
}
```

**Testing Benefits:**

- **Fast execution** - No database required
- **Focused verification** - Tests business rules in isolation
- **Clear expectations** - Verifies service behavior without HTTP concerns
- **Complete coverage** - Happy paths and edge cases

---

## 11. Key Architecture Principles Summary

1. **Controllers are thin** - Only handle HTTP concerns, validation, and status codes

2. **Services contain business logic** - Including validation, mapping, and transaction management

3. **Repositories are pure data access** - No business rules, just query methods

4. **DTO conversion happens in services** - Never in controllers

5. **Entities remain hidden** - Never exposed beyond the service layer

6. **Validation happens at boundaries** - Fail fast with clear error messages

7. **Transaction boundaries are in services** - Ensures data consistency

8. **Layered testing** - Service tests without database dependencies

This architecture creates a robust foundation that supports clean code, easy maintenance, and scalable growth as application requirements evolve.