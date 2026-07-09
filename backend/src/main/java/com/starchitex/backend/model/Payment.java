package com.starchitex.backend.model;

import java.time.LocalDateTime;
import java.math.BigDecimal;

public record Payment(
    Integer paymentId,
    Integer invoiceId,
    LocalDateTime paymentDate,
    BigDecimal amount,
    String paymentMethod,
    String transactionRef
) {}
