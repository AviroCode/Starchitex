package com.starchitex.backend.model;

import java.math.BigDecimal;

public record RoomType(
    Integer roomTypeId,
    String typeName,
    String description,
    BigDecimal basePrice,
    Integer capacity
) {}
