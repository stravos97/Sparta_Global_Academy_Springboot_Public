package com.sparta.spartaglobalacademy.repositories;

import com.sparta.spartaglobalacademy.entities.TrainerEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TrainerRepository extends JpaRepository<TrainerEntity, Integer> {

}
