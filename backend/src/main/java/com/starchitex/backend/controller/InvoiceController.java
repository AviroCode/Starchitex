package com.starchitex.backend.controller;

import com.starchitex.backend.model.Invoice;
import com.starchitex.backend.service.InvoiceService;
import org.springframework.http.ResponseEntity;
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

    @PostMapping
    public ResponseEntity<String> createInvoice(@RequestBody Invoice invoice) {
        boolean isCreated = invoiceService.createInvoice(invoice);
        if (isCreated) {
            return ResponseEntity.status(201).body("Invoice created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create invoice.");
        }
    }

    @PutMapping("/{invoiceId}")
    public ResponseEntity<String> updateInvoice(@PathVariable int invoiceId, @RequestBody Invoice invoice) {
        Invoice invoiceToUpdate = new Invoice(
                invoiceId,
                invoice.reservationId(),
                invoice.payerGuestId(),
                invoice.invoiceDate(),
                invoice.subTotal(),
                invoice.taxAmount(),
                invoice.discount(),
                invoice.totalAmount(),
                invoice.status()
        );

        boolean isUpdated = invoiceService.updateInvoice(invoiceToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Invoice updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update invoice. Check if ID exists.");
        }
    }
}
