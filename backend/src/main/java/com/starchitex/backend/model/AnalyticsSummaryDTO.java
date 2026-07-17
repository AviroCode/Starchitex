package com.starchitex.backend.model;

import java.math.BigDecimal;

public record AnalyticsSummaryDTO(
    Integer totalRooms,
    Integer occupiedToday,
    BigDecimal occupancyRateToday,   // occupiedToday / totalRooms
    Integer roomNightsThisMonth,
    BigDecimal revenueThisMonth,
    BigDecimal adr,                  // revenueThisMonth / roomNightsThisMonth
    BigDecimal revpar                // revenueThisMonth / (totalRooms * daysElapsedThisMonth)
) {}
