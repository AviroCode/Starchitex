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
        Invoice invoice = invoiceService.getInvoiceById(payment.invoiceId())
                .orElseThrow(() -> new IllegalArgumentException("Invoice not found"));

        List<Payment> existingPayments = paymentRepository.findByInvoiceId(invoice.invoiceId());
        BigDecimal currentPaid = existingPayments.stream()
                .map(Payment::amount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal newTotalPaid = currentPaid.add(payment.amount());

        if (newTotalPaid.compareTo(invoice.totalAmount()) > 0) {
            throw new IllegalArgumentException("Payment exceeds total invoice amount. Outstanding: " + invoice.totalAmount().subtract(currentPaid));
        }

        boolean saved = paymentRepository.save(payment) > 0;

        if (saved) {
            String newStatus = newTotalPaid.compareTo(invoice.totalAmount()) == 0 ? "Paid" : "Partially Paid";
            if (!invoice.status().equals(newStatus)) {
                Invoice updatedInvoice = new Invoice(
                    invoice.invoiceId(), invoice.reservationId(), invoice.payerGuestId(),
                    invoice.invoiceDate(), invoice.subTotal(), invoice.taxAmount(),
                    invoice.discount(), invoice.totalAmount(), newStatus
                );
                invoiceService.updateInvoice(updatedInvoice);
            }
        }
        return saved;
    }

    public boolean updatePayment(Payment payment) {
        return paymentRepository.update(payment) > 0;
    }
}
