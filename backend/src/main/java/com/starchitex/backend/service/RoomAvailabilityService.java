package com.starchitex.backend.service;

import com.starchitex.backend.model.RoomAvailability;
import com.starchitex.backend.repository.RoomAvailabilityRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class RoomAvailabilityService {

    private final RoomAvailabilityRepository roomAvailabilityRepository;

    public RoomAvailabilityService(RoomAvailabilityRepository roomAvailabilityRepository) {
        this.roomAvailabilityRepository = roomAvailabilityRepository;
    }

    public List<RoomAvailability> getAllAvailabilities() {
        return roomAvailabilityRepository.findAll();
    }

    public Optional<RoomAvailability> getAvailabilityById(int availabilityId) {
        return roomAvailabilityRepository.findById(availabilityId);
    }

    public List<RoomAvailability> getAvailabilitiesByRoomId(int roomId) {
        return roomAvailabilityRepository.findByRoomId(roomId);
    }

    public boolean createAvailability(RoomAvailability availability) {
        return roomAvailabilityRepository.save(availability) > 0;
    }

    public boolean updateAvailability(RoomAvailability availability) {
        return roomAvailabilityRepository.update(availability) > 0;
    }
}
