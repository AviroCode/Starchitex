package com.starchitex.backend.model;

import java.math.BigDecimal;

public record Service(
    Integer serviceId,
    String serviceName,
    String category,
    BigDecimal price,
    String description
) {}
