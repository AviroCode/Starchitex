package com.starchitex.backend.service;

import com.starchitex.backend.model.FacilityTask;
import com.starchitex.backend.repository.FacilityTaskRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class FacilityTaskService {

    private final FacilityTaskRepository facilityTaskRepository;

    public FacilityTaskService(FacilityTaskRepository facilityTaskRepository) {
        this.facilityTaskRepository = facilityTaskRepository;
    }

    public List<FacilityTask> getAllTasks() {
        return facilityTaskRepository.findAll();
    }

    public Optional<FacilityTask> getTaskById(int facilitytaskId) {
        return facilityTaskRepository.findById(facilitytaskId);
    }

    public List<FacilityTask> getTasksByFacilityId(int facilityId) {
        return facilityTaskRepository.findByFacilityId(facilityId);
    }

    public boolean createTask(FacilityTask task) {
        return facilityTaskRepository.save(task) > 0;
    }

    public boolean updateTask(FacilityTask task) {
        return facilityTaskRepository.update(task) > 0;
    }
}
