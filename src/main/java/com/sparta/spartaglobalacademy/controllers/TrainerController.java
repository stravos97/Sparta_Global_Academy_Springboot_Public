package com.sparta.spartaglobalacademy.controllers;

import com.sparta.spartaglobalacademy.entities.TrainerEntity;
import com.sparta.spartaglobalacademy.records.TrainerRecord;
import com.sparta.spartaglobalacademy.records.TrainerMapper;
import com.sparta.spartaglobalacademy.services.TrainerService;
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
@RequestMapping("/trainers")
@Validated
public class TrainerController {

    private final TrainerService service;
    private final TrainerMapper trainerMapper;

    public TrainerController(TrainerService service, TrainerMapper trainerMapper) {
        this.service = service;
        this.trainerMapper = trainerMapper;
    }

    // GET all trainers
    @Operation(summary = "Get all trainers", description = "Retrieve a list of all trainers")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "List of trainers",
                    content = @Content(array = @ArraySchema(schema = @Schema(implementation = TrainerRecord.class))))
    })
    @GetMapping
    public ResponseEntity<List<TrainerRecord>> getAllTrainers() {
        List<TrainerRecord> trainers = service.getAllTrainers();
        return ResponseEntity.ok(trainers);
    }


    // GET trainer by ID
    @Operation(summary = "Get trainer by ID", description = "Retrieve a single trainer by their ID")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Trainer found",
                    content = @Content(schema = @Schema(implementation = TrainerRecord.class))),
            @ApiResponse(responseCode = "404", description = "Trainer not found", content = @Content)
    })
    @GetMapping("/{id}")
    public ResponseEntity<TrainerRecord> getTrainerById(@Min(1) @PathVariable Integer id) {
        TrainerRecord trainer = service.getTrainerById(id);
        return ResponseEntity.ok(trainer);
    }

    // CREATE a new trainer
    @Operation(summary = "Add a new trainer", description = "Create a new trainer in the system")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Trainer created",
                    content = @Content(schema = @Schema(implementation = TrainerRecord.class))),
            @ApiResponse(responseCode = "400", description = "Invalid input", content = @Content)
    })
    @PostMapping
    public ResponseEntity<TrainerRecord> addTrainer(@Valid @RequestBody TrainerRecord trainerRecord) {
        TrainerEntity trainerEntity = trainerMapper.toEntity(trainerRecord);
        TrainerRecord savedTrainer = service.createTrainer(trainerEntity);
        return ResponseEntity.status(201).body(savedTrainer);
    }

    // UPDATE an existing trainer
    @Operation(summary = "Update a trainer", description = "Update an existing trainer by ID")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Trainer updated",
                    content = @Content(schema = @Schema(implementation = TrainerRecord.class))),
            @ApiResponse(responseCode = "400", description = "Invalid input", content = @Content),
            @ApiResponse(responseCode = "404", description = "Trainer not found", content = @Content)
    })
    @PutMapping("/{id}")
    public ResponseEntity<TrainerRecord> updateTrainer(
            @Min(1) @PathVariable Integer id,
            @Valid @RequestBody TrainerRecord trainerRecord
    ) {
        TrainerEntity trainerEntity = trainerMapper.toEntity(trainerRecord);
        TrainerRecord updatedTrainer = service.updateTrainer(id, trainerEntity);
        return ResponseEntity.ok(updatedTrainer);
    }

    // DELETE a trainer
    @Operation(summary = "Delete a trainer", description = "Delete a trainer by ID")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Trainer deleted", content = @Content),
            @ApiResponse(responseCode = "404", description = "Trainer not found", content = @Content)
    })
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTrainer(@Min(1) @PathVariable Integer id) {
        boolean deleted = service.deleteTrainerById(id);
        return deleted ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }
}
