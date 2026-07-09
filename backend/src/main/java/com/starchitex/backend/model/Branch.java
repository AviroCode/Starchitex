package com.starchitex.backend.model;

public record Branch(
    Integer branchId,
    String name,
    String address,
    String city,
    String province,
    String postalCode,
    String email,
    String phone,
    String status
) {}
