package com.sparta.spartaglobalacademy.services;

import com.sparta.spartaglobalacademy.entities.TrainerEntity;
import com.sparta.spartaglobalacademy.records.TrainerRecord;
import com.sparta.spartaglobalacademy.records.TrainerMapper;
import com.sparta.spartaglobalacademy.repositories.TrainerRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;

@Service
public class TrainerService {

    private final TrainerRepository trainerRepository;
    private final TrainerMapper trainerMapper;

    public TrainerService(TrainerRepository trainerRepository, TrainerMapper trainerMapper) {
        if (trainerRepository == null) {
            throw new IllegalArgumentException("trainerRepository cannot be null");
        }
        if (trainerMapper == null) {
            throw new IllegalArgumentException("trainerMapper cannot be null");
        }
        this.trainerRepository = trainerRepository;
        this.trainerMapper = trainerMapper;
    }

    // GET all trainers (no streams)
    public List<TrainerRecord> getAllTrainers() {
        List<TrainerEntity> entities = trainerRepository.findAll();
        ArrayList<TrainerRecord> results = new ArrayList<>();
        for (TrainerEntity e : entities) {
            results.add(trainerMapper.toRecord(e));
        }
        return results;
    }

    // GET trainer by ID
    public TrainerRecord getTrainerById(Integer id) {
        TrainerEntity entity = trainerRepository.findById(id).orElse(null);
        if (entity == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Trainer not found with ID: " + id);
        }
        return trainerMapper.toRecord(entity);
    }

    // CREATE a new trainer
    public TrainerRecord createTrainer(TrainerEntity trainerEntity) {
        if (trainerEntity == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Trainer entity cannot be null");
        }
        TrainerEntity savedTrainer = trainerRepository.save(trainerEntity);
        return trainerMapper.toRecord(savedTrainer);
    }

    // UPDATE an existing trainer
    public TrainerRecord updateTrainer(Integer id, TrainerEntity updatedTrainer) {
        if (id == null || updatedTrainer == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Trainer ID and entity cannot be null");
        }

        if (!trainerRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Trainer not found with ID: " + id);
        }

        updatedTrainer.setId(id);
        TrainerEntity saved = trainerRepository.save(updatedTrainer);
        return trainerMapper.toRecord(saved);
    }

    // DELETE a trainer (return boolean)
    public boolean deleteTrainerById(Integer id) {
        if (trainerRepository.existsById(id)) {
            trainerRepository.deleteById(id);
            return true;
        }
        return false;
    }
}
