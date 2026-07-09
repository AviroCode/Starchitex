package com.starchitex.backend.service;

import com.starchitex.backend.model.Service;
import com.starchitex.backend.repository.ServiceRepository;

import java.util.List;
import java.util.Optional;

@org.springframework.stereotype.Service("hotelServiceService")
public class ServiceService {

    private final ServiceRepository serviceRepository;

    public ServiceService(ServiceRepository serviceRepository) {
        this.serviceRepository = serviceRepository;
    }

    public List<Service> getAllServices() {
        return serviceRepository.findAll();
    }

    public Optional<Service> getServiceById(int id) {
        return serviceRepository.findById(id);
    }

    public boolean createService(Service service) {
        return serviceRepository.save(service) > 0;
    }

    public boolean updateService(Service service) {
        return serviceRepository.update(service) > 0;
    }
}
