package com.starchitex.backend.model;

import java.time.LocalDateTime;
import java.math.BigDecimal;

public record Invoice(
    Integer invoiceId,
    Integer reservationId,
    Integer payerGuestId,
    LocalDateTime invoiceDate,
    BigDecimal subTotal,
    BigDecimal taxAmount,
    BigDecimal discount,
    BigDecimal totalAmount,
    String status
) {}
