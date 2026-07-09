package com.starchitex.backend.model;

public record Facility(
    Integer facilityId,
    Integer branchId,
    String facilityName,
    String description,
    Integer capacity,
    String location
) {}
