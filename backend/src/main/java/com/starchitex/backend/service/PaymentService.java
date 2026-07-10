package com.starchitex.backend.service;

import com.starchitex.backend.model.Payment;
import com.starchitex.backend.repository.PaymentRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.starchitex.backend.model.Invoice;
import java.math.BigDecimal;

import java.util.List;
import java.util.Optional;

@Service
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final InvoiceService invoiceService;

    public PaymentService(PaymentRepository paymentRepository, InvoiceService invoiceService) {
        this.paymentRepository = paymentRepository;
        this.invoiceService = invoiceService;
    }

    public List<Payment> getAllPayments() {
        return paymentRepository.findAll();
    }

    public Optional<Payment> getPaymentById(int paymentId) {
        return paymentRepository.findById(paymentId);
    }

    public List<Payment> getPaymentsByInvoiceId(int invoiceId) {
        return paymentRepository.findByInvoiceId(invoiceId);
    }

    @Transactional
    public boolean createPayment(Payment payment) {
        // Overpayment is enforced by trg_prevent_overpayment (BEFORE INSERT on Payment).
        // Status updates to Paid/Partially Paid are handled by trg_update_invoice_status (AFTER INSERT/DELETE on Payment).
        return paymentRepository.save(payment) > 0;
    }

    public boolean updatePayment(Payment payment) {
        return paymentRepository.update(payment) > 0;
    }
}
