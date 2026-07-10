package com.starchitex.backend.service;

import com.starchitex.backend.model.RoomMaintenance;
import com.starchitex.backend.repository.RoomMaintenanceRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class RoomMaintenanceService {

    private final RoomMaintenanceRepository roomMaintenanceRepository;

    public RoomMaintenanceService(RoomMaintenanceRepository roomMaintenanceRepository) {
        this.roomMaintenanceRepository = roomMaintenanceRepository;
    }

    public List<RoomMaintenance> getAllMaintenanceTickets() {
        return roomMaintenanceRepository.findAll();
    }

    public Optional<RoomMaintenance> getMaintenanceTicketById(int roomMaintenanceId) {
        return roomMaintenanceRepository.findById(roomMaintenanceId);
    }

    public List<RoomMaintenance> getMaintenanceTicketsByRoomId(int roomId) {
        return roomMaintenanceRepository.findByRoomId(roomId);
    }

    public boolean createMaintenanceTicket(RoomMaintenance maintenance) {
        return roomMaintenanceRepository.save(maintenance) > 0;
    }

    public boolean updateMaintenanceTicket(RoomMaintenance maintenance) {
        return roomMaintenanceRepository.update(maintenance) > 0;
    }
}
