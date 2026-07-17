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
        // The DB column defaults to 'Reported', but that default only
        // applies when the column is omitted from the INSERT entirely — a
        // request body without a status field deserializes to an explicit
        // null here, which the repository's save() then passes through and
        // trips the NOT NULL constraint. Force the same default in Java.
        RoomMaintenance withStatus = maintenance.status() != null ? maintenance : new RoomMaintenance(
                maintenance.roomMaintenanceId(),
                maintenance.roomId(),
                maintenance.reportedBy(),
                maintenance.assignedEmployeeId(),
                maintenance.reportDate(),
                maintenance.priority(),
                maintenance.completionDate(),
                maintenance.description(),
                "Reported"
        );
        return roomMaintenanceRepository.save(withStatus) > 0;
    }

    public boolean updateMaintenanceTicket(RoomMaintenance maintenance) {
        return roomMaintenanceRepository.update(maintenance) > 0;
    }
}
