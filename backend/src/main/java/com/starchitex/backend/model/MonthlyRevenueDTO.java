package com.starchitex.backend.model;

import java.math.BigDecimal;

public record MonthlyRevenueDTO(
    Integer invoiceYear,
    Integer invoiceMonth,
    Integer totalInvoices,
    BigDecimal totalRevenue
) {}
