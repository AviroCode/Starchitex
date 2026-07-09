package com.starchitex.backend.model;

import java.math.BigDecimal;

public record InvoiceItem(
    Integer invoiceItemId,
    Integer invoiceId,
    String itemType,
    Integer quantity,
    BigDecimal amount
) {}
