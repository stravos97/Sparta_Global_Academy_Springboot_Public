package com.sparta.spartaglobalacademy.records;

import com.sparta.spartaglobalacademy.entities.CourseEntity;
import com.sparta.spartaglobalacademy.entities.TrainerEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

@Mapper(componentModel = "spring")
public interface CourseMapper {

    CourseMapper INSTANCE = Mappers.getMapper(CourseMapper.class);

    // Entity -> Record
    @Mapping(target = "trainerId", source = "trainer.id")
    CourseRecord toRecord(CourseEntity course);

    // Record -> Entity
    @Mapping(target = "trainer", expression = "java(fromTrainerId(courseRecord.trainerId()))")
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    CourseEntity toEntity(CourseRecord courseRecord);

    // Helper method for mapping trainerId -> TrainerEntity
    default TrainerEntity fromTrainerId(Integer trainerId) {
        if (trainerId == null) {
            return null;
        }
        TrainerEntity trainer = new TrainerEntity();
        trainer.setId(trainerId);
        return trainer;
    }
}
