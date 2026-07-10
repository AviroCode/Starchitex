package com.starchitex.backend.service;

import com.starchitex.backend.model.FacilityMaintenance;
import com.starchitex.backend.repository.FacilityMaintenanceRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class FacilityMaintenanceService {

    private final FacilityMaintenanceRepository facilityMaintenanceRepository;

    public FacilityMaintenanceService(FacilityMaintenanceRepository facilityMaintenanceRepository) {
        this.facilityMaintenanceRepository = facilityMaintenanceRepository;
    }

    public List<FacilityMaintenance> getAllMaintenanceTickets() {
        return facilityMaintenanceRepository.findAll();
    }

    public Optional<FacilityMaintenance> getMaintenanceTicketById(int facilityMaintenanceId) {
        return facilityMaintenanceRepository.findById(facilityMaintenanceId);
    }

    public List<FacilityMaintenance> getMaintenanceTicketsByFacilityId(int facilityId) {
        return facilityMaintenanceRepository.findByFacilityId(facilityId);
    }

    public boolean createMaintenanceTicket(FacilityMaintenance maintenance) {
        return facilityMaintenanceRepository.save(maintenance) > 0;
    }

    public boolean updateMaintenanceTicket(FacilityMaintenance maintenance) {
        return facilityMaintenanceRepository.update(maintenance) > 0;
    }
}
