package com.starchitex.backend.model;

public record Permission(
    Integer permissionId,
    String permissionName,
    String description
) {}
