package com.starchitex.backend.service;

import com.starchitex.backend.model.Facility;
import com.starchitex.backend.repository.FacilityRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class FacilityService {

    private final FacilityRepository facilityRepository;

    public FacilityService(FacilityRepository facilityRepository) {
        this.facilityRepository = facilityRepository;
    }

    public List<Facility> getAllFacilities() {
        return facilityRepository.findAll();
    }

    public Optional<Facility> getFacilityById(int id) {
        return facilityRepository.findById(id);
    }

    public List<Facility> getFacilitiesByBranchId(int branchId) {
        return facilityRepository.findByBranchId(branchId);
    }

    public boolean createFacility(Facility facility) {
        return facilityRepository.save(facility) > 0;
    }

    public boolean updateFacility(Facility facility) {
        return facilityRepository.update(facility) > 0;
    }
}
