package com.starchitex.backend.model;

import java.math.BigDecimal;

public record InvoiceItem(
    Integer invoiceItemId,
    Integer invoiceId,
    Integer roomId,        // nullable — set for Room, Damage, Maintenance
    Integer serviceId,     // nullable — set for Service
    String itemType,       // Room | Service | Damage | Maintenance | Other
    Integer quantity,
    BigDecimal amount,
    String description     // nullable — optional staff note
) {}
