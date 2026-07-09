package com.starchitex.backend.model;

public record Room(
    Integer roomId,
    String roomNumber,
    Integer floor,
    Integer branchId,
    Integer roomTypeId
) {}
