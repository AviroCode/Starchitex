package com.starchitex.backend.controller;

import com.starchitex.backend.model.Invoice;
import com.starchitex.backend.service.InvoiceService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/invoices")
public class InvoiceController {

    private final InvoiceService invoiceService;

    public InvoiceController(InvoiceService invoiceService) {
        this.invoiceService = invoiceService;
    }

    @GetMapping
    public List<Invoice> getAllInvoices() {
        return invoiceService.getAllInvoices();
    }

    @GetMapping("/{invoiceId}")
    public ResponseEntity<Invoice> getInvoiceById(@PathVariable int invoiceId) {
        return invoiceService.getInvoiceById(invoiceId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/reservation/{reservationId}")
    public List<Invoice> getInvoicesByReservationId(@PathVariable int reservationId) {
        return invoiceService.getInvoicesByReservationId(reservationId);
    }
    
    @GetMapping("/guest/{payerGuestId}")
    public List<Invoice> getInvoicesByPayerGuestId(@PathVariable int payerGuestId) {
        return invoiceService.getInvoicesByPayerGuestId(payerGuestId);
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PostMapping
    public ResponseEntity<String> createInvoice(@RequestBody Invoice invoice) {
        boolean isCreated = invoiceService.createInvoice(invoice);
        if (isCreated) {
            return ResponseEntity.status(201).body("Invoice created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create invoice.");
        }
    }

    // Records that staff processed a refund outside the app (cash, bank
    // transfer, reversing a card charge, etc.) — see InvoiceRepository.markRefunded.
    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PostMapping("/{invoiceId}/mark-refunded")
    public ResponseEntity<String> markRefunded(@PathVariable int invoiceId) {
        boolean success = invoiceService.markRefunded(invoiceId);
        return success ? ResponseEntity.ok("Invoice marked as refunded.") : ResponseEntity.badRequest().body("Failed to mark invoice as refunded.");
    }
}
