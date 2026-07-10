package com.starchitex.backend.service;

import com.starchitex.backend.model.ServiceRequest;
import com.starchitex.backend.repository.ServiceRequestRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ServiceRequestService {

    private final ServiceRequestRepository serviceRequestRepository;

    public ServiceRequestService(ServiceRequestRepository serviceRequestRepository) {
        this.serviceRequestRepository = serviceRequestRepository;
    }

    public List<ServiceRequest> getAllServiceRequests() {
        return serviceRequestRepository.findAll();
    }

    public Optional<ServiceRequest> getServiceRequestById(int requestId) {
        return serviceRequestRepository.findById(requestId);
    }

    public List<ServiceRequest> getServiceRequestsByReservationId(int reservationId) {
        return serviceRequestRepository.findByReservationId(reservationId);
    }

    public boolean createServiceRequest(ServiceRequest request) {
        return serviceRequestRepository.save(request) > 0;
    }

    public boolean updateServiceRequest(ServiceRequest request) {
        return serviceRequestRepository.update(request) > 0;
    }
}
