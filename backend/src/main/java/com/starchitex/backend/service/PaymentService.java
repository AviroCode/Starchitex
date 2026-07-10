package com.starchitex.backend.service;

import com.starchitex.backend.model.Payment;
import com.starchitex.backend.repository.PaymentRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class PaymentService {

    private final PaymentRepository paymentRepository;

    public PaymentService(PaymentRepository paymentRepository) {
        this.paymentRepository = paymentRepository;
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

    public boolean createPayment(Payment payment) {
        return paymentRepository.save(payment) > 0;
    }

    public boolean updatePayment(Payment payment) {
        return paymentRepository.update(payment) > 0;
    }
}
