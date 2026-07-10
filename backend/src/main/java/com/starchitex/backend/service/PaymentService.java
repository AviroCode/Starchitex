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
        // If it triggers, an exception propagates here and rolls back the transaction.
        boolean saved = paymentRepository.save(payment) > 0;

        if (saved) {
            // Update invoice status to Paid or Partially Paid based on totals
            Invoice invoice = invoiceService.getInvoiceById(payment.invoiceId())
                    .orElseThrow(() -> new IllegalArgumentException("Invoice not found"));

            List<Payment> allPayments = paymentRepository.findByInvoiceId(payment.invoiceId());
            BigDecimal totalPaid = allPayments.stream()
                    .map(p -> p.amount())
                    .reduce(BigDecimal.ZERO, (a, b) -> a.add(b));

            String newStatus = totalPaid.compareTo(invoice.totalAmount()) >= 0 ? "Paid" : "Partially Paid";
            if (!invoice.status().equals(newStatus)) {
                Invoice updated = new Invoice(
                    invoice.invoiceId(), invoice.reservationId(), invoice.payerGuestId(),
                    invoice.invoiceDate(), invoice.subTotal(), invoice.taxAmount(),
                    invoice.discount(), invoice.totalAmount(), newStatus
                );
                invoiceService.updateInvoice(updated);
            }
        }
        return saved;
    }

    public boolean updatePayment(Payment payment) {
        return paymentRepository.update(payment) > 0;
    }
}
