package com.starchitex.backend.controller;

import com.starchitex.backend.model.Payment;
import com.starchitex.backend.service.PaymentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/payments")
public class PaymentController {

    private final PaymentService paymentService;

    public PaymentController(PaymentService paymentService) {
        this.paymentService = paymentService;
    }

    @GetMapping
    public List<Payment> getAllPayments() {
        return paymentService.getAllPayments();
    }

    @GetMapping("/{paymentId}")
    public ResponseEntity<Payment> getPaymentById(@PathVariable int paymentId) {
        return paymentService.getPaymentById(paymentId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/invoice/{invoiceId}")
    public List<Payment> getPaymentsByInvoiceId(@PathVariable int invoiceId) {
        return paymentService.getPaymentsByInvoiceId(invoiceId);
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PostMapping
    public ResponseEntity<String> createPayment(@RequestBody Payment payment) {
        boolean isCreated = paymentService.createPayment(payment);
        if (isCreated) {
            return ResponseEntity.status(201).body("Payment recorded successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to record payment.");
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PutMapping("/{paymentId}")
    public ResponseEntity<String> updatePayment(@PathVariable int paymentId, @RequestBody Payment payment) {
        Payment paymentToUpdate = new Payment(
                paymentId,
                payment.invoiceId(),
                payment.paymentDate(),
                payment.amount(),
                payment.paymentMethod(),
                payment.transactionRef()
        );

        boolean isUpdated = paymentService.updatePayment(paymentToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Payment updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update payment. Check if ID exists.");
        }
    }
}
