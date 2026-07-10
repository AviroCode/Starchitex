package com.starchitex.backend.service;

import com.starchitex.backend.model.Room;
import com.starchitex.backend.repository.RoomRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class RoomService {

    private final RoomRepository roomRepository;

    public RoomService(RoomRepository roomRepository) {
        this.roomRepository = roomRepository;
    }

    public List<Room> getAllRooms() {
        return roomRepository.findAll();
    }

    public Optional<Room> getRoomById(int id) {
        return roomRepository.findById(id);
    }

    public List<Room> getRoomsByBranchId(int branchId) {
        return roomRepository.findByBranchId(branchId);
    }

    public boolean createRoom(Room room) {
        return roomRepository.save(room) > 0;
    }

    public boolean updateRoom(Room room) {
        return roomRepository.update(room) > 0;
    }
}
