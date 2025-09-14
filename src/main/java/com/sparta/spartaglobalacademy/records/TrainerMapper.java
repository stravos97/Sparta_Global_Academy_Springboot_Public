package com.sparta.spartaglobalacademy.records;

import com.sparta.spartaglobalacademy.entities.TrainerEntity;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.factory.Mappers;

@Mapper(componentModel = "spring")
public interface TrainerMapper {

    TrainerMapper INSTANCE = Mappers.getMapper(TrainerMapper.class);

    // Entity -> Record
    TrainerRecord toRecord(TrainerEntity trainer);

    // Record -> Entity
    @Mapping(target = "createdAt", ignore = true)
    @Mapping(target = "updatedAt", ignore = true)
    TrainerEntity toEntity(TrainerRecord trainerRecord);
}
