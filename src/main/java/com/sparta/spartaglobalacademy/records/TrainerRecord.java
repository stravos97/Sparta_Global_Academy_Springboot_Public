package com.sparta.spartaglobalacademy.records;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(name = "Trainer", description = "Record for Trainer")
public record TrainerRecord(
        @Schema(description = "Trainer ID", example = "1")
        Integer id,

        @Schema(description = "Full name of the trainer", example = "John Doe")
        String fullName
) {}
