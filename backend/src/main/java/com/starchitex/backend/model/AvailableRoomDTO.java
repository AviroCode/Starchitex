package com.starchitex.backend.model;

import java.math.BigDecimal;

public record AvailableRoomDTO(
    Integer roomId,
    String roomNumber,
    Integer floor,
    String typeName,
    BigDecimal priceOverride,
    String status
) {}
