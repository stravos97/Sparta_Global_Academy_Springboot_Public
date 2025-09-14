package com.sparta.spartaglobalacademy.services;

import com.sparta.spartaglobalacademy.entities.TrainerEntity;
import com.sparta.spartaglobalacademy.records.TrainerRecord;
import com.sparta.spartaglobalacademy.records.TrainerMapper;
import com.sparta.spartaglobalacademy.repositories.TrainerRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.springframework.web.server.ResponseStatusException;
import java.util.Optional;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TrainerServiceTest {

    @Mock
    private TrainerRepository mockTrainerRepository;

    @Mock
    private TrainerMapper trainerMapper;

    @InjectMocks
    private TrainerService trainerService;

@Test
@DisplayName("getTrainerById throws ResponseStatusException when trainer does not exist")
void getTrainerByIdThrowsExceptionIfNotExists() {
    // Arrange
    Integer trainerId = 2;
    when(mockTrainerRepository.findById(trainerId)).thenReturn(java.util.Optional.empty());

    // Act & Assert
    ResponseStatusException ex = assertThrows(
            ResponseStatusException.class,
            () -> trainerService.getTrainerById(trainerId)
    );

    // Optionally check the exception message and status
    assertThat(ex.getStatusCode().value()).isEqualTo(404);
    assertThat(ex.getReason()).isEqualTo("Trainer not found with ID: 2");
}
    // Happy Path: GETTrainerbyId
    @Test
    @DisplayName("getTrainerById returns trainer when found")
    void getTrainerByIdReturnsTrainerIfExists() {
        // Arrange
        Integer trainerId = 1;

        TrainerEntity trainerEntity = new TrainerEntity();
        trainerEntity.setId(trainerId);
        trainerEntity.setFullName("Alice Smith");

        var trainerRecord = new TrainerRecord(trainerId, "Alice Smith");

        when(mockTrainerRepository.findById(trainerId)).thenReturn(java.util.Optional.of(trainerEntity));
        when(trainerMapper.toRecord(trainerEntity)).thenReturn(trainerRecord);

        // Act
        var result = trainerService.getTrainerById(trainerId);

        // Assert
        assertThat(result).isNotNull();
        assertThat(result.id()).isEqualTo(1);
        assertThat(result.fullName()).isEqualTo("Alice Smith");
    }

    //HappyPath - GetAllTrainers
    @Test
    @DisplayName("getAllTrainers should return list of trainers when present")
    void getAllTrainersReturnsListWhenPresent() {
        // Arrange
        TrainerEntity t1 = new TrainerEntity();
        t1.setId(1);
        t1.setFullName("Alice");

        TrainerEntity t2 = new TrainerEntity();
        t2.setId(2);
        t2.setFullName("Bob");

        TrainerRecord record1 = new TrainerRecord(1, "Alice");
        TrainerRecord record2 = new TrainerRecord(2, "Bob");

        when(mockTrainerRepository.findAll()).thenReturn(List.of(t1, t2));
        when(trainerMapper.toRecord(t1)).thenReturn(record1);
        when(trainerMapper.toRecord(t2)).thenReturn(record2);

        // Act
        List<TrainerRecord> result = trainerService.getAllTrainers();

        // Assert
        assertThat(result).hasSize(2);
        assertThat(result).extracting(TrainerRecord::fullName)
                .containsExactlyInAnyOrder("Alice", "Bob");
    }

    // Sad Path - Get All trainer returns empty list
    @Test
    @DisplayName("getAllTrainers should return empty list when no trainers exist")
    void getAllTrainersReturnEmptyListWhenNoTrainersExist() {
        when(mockTrainerRepository.findAll()).thenReturn(List.of());

        //Act
        List<TrainerRecord> result = trainerService.getAllTrainers();
        //Assert
        assertThat(result).isEmpty();
    }

    // Happy Path - Create Trainer
    @Test
    @DisplayName("createTrainer should save trainer when valid")
    void createTrainerSavesAndReturnsRecord() {
        // Arrange
        TrainerEntity trainerEntity = new TrainerEntity();
        trainerEntity.setFullName("Alice Smith");

        // Simulate repo saving and assigning an ID
        TrainerEntity savedEntity = new TrainerEntity();
        savedEntity.setId(1);
        savedEntity.setFullName("Alice Smith");

        TrainerRecord trainerRecord = new TrainerRecord(1, "Alice Smith");

        when(mockTrainerRepository.save(trainerEntity)).thenReturn(savedEntity);
        when(trainerMapper.toRecord(savedEntity)).thenReturn(trainerRecord);

        // Act
        TrainerRecord result = trainerService.createTrainer(trainerEntity);

        // Assert
        assertThat(result).isNotNull();
        assertThat(result.id()).isEqualTo(1);
        assertThat(result.fullName()).isEqualTo("Alice Smith");
    }
    // Sad Path - CreateTrainer should throw if entity is null
    @Test
    @DisplayName("createTrainer should throw when trainer entity is null")
    void createTrainerThrowsWhenTrainerEntityIsNull() {
        // Act & Assert
        assertThrows(ResponseStatusException.class,
                () -> trainerService.createTrainer(null));
    }

    // Happy Path - Update Trainers should update and return when valid
    @Test
    @DisplayName("updateTrainer should update and return trainer when valid")
    void updateTrainerSavesAndReturnsRecord() {
        // Arrange
        Integer trainerId = 1;
        TrainerEntity trainerEntity = new TrainerEntity();
        trainerEntity.setId(trainerId);
        trainerEntity.setFullName("Updated Name");

        TrainerRecord trainerRecord = new TrainerRecord(1, "Updated Name");

        when(mockTrainerRepository.existsById(trainerId)).thenReturn(true);
        when(mockTrainerRepository.save(trainerEntity)).thenReturn(trainerEntity);
        when(trainerMapper.toRecord(trainerEntity)).thenReturn(trainerRecord);

        // Act
        TrainerRecord result = trainerService.updateTrainer(trainerId, trainerEntity);

        // Assert
        assertThat(result).isNotNull();
        assertThat(result.id()).isEqualTo(1);
        assertThat(result.fullName()).isEqualTo("Updated Name");
    }

    // Sad path - Update null trainer
    @Test
    @DisplayName("updateTrainer should throw when trainer is null")
    void updateTrainerThrowsWhenTrainerIsNull() {
        assertThrows(ResponseStatusException.class,
                () -> trainerService.updateTrainer(1, null));
    }

    @Test
    @DisplayName("deleteTrainerById should delete trainer when ID exists")
    void testDeleteTrainerByIdSuccess() {
        // Arrange
        Integer trainerId = 1;

        when(mockTrainerRepository.existsById(trainerId)).thenReturn(true);

        // Act
        trainerService.deleteTrainerById(trainerId);

        // Assert
        verify(mockTrainerRepository).deleteById(trainerId);
    }

    @Test
    @DisplayName("updateTrainer should throw exception when trainer does not exist")
    void testUpdateTrainerByIdNotFound() {
        // Arrange
        Integer trainerId = 99;
        TrainerEntity updatedEntity = new TrainerEntity();
        updatedEntity.setFullName("Updated Name");

        when(mockTrainerRepository.existsById(trainerId)).thenReturn(false);

        // Act & Assert
        assertThrows(ResponseStatusException.class,
                () -> trainerService.updateTrainer(trainerId, updatedEntity),
                "Expected ResponseStatusException when trainer does not exist");
    }

    @Test
    @DisplayName("deleteTrainerById should throw exception when trainer does not exist")
    void testDeleteTrainerByIdNotFound() {
        // Arrange
        Integer trainerId = 99;

        when(mockTrainerRepository.existsById(trainerId)).thenReturn(false);

        // The service method returns false when trainer doesn't exist, it doesn't throw
        boolean result = trainerService.deleteTrainerById(trainerId);
        
        assertThat(result).isFalse();
    }
}
