package com.starchitex.backend.service;

import com.starchitex.backend.model.RoomType;
import com.starchitex.backend.repository.RoomTypeRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class RoomTypeService {

    private final RoomTypeRepository roomTypeRepository;

    public RoomTypeService(RoomTypeRepository roomTypeRepository) {
        this.roomTypeRepository = roomTypeRepository;
    }

    public List<RoomType> getAllRoomTypes() {
        return roomTypeRepository.findAll();
    }

    public Optional<RoomType> getRoomTypeById(int id) {
        return roomTypeRepository.findById(id);
    }

    public boolean createRoomType(RoomType roomType) {
        return roomTypeRepository.save(roomType) > 0;
    }

    public boolean updateRoomType(RoomType roomType) {
        return roomTypeRepository.update(roomType) > 0;
    }
}
