package com.starchitex.backend.service;

import com.starchitex.backend.model.Invoice;
import com.starchitex.backend.repository.InvoiceRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class InvoiceService {

    private final InvoiceRepository invoiceRepository;

    public InvoiceService(InvoiceRepository invoiceRepository) {
        this.invoiceRepository = invoiceRepository;
    }

    public List<Invoice> getAllInvoices() {
        return invoiceRepository.findAll();
    }

    public Optional<Invoice> getInvoiceById(int invoiceId) {
        return invoiceRepository.findById(invoiceId);
    }

    public List<Invoice> getInvoicesByReservationId(int reservationId) {
        return invoiceRepository.findByReservationId(reservationId);
    }
    
    public List<Invoice> getInvoicesByPayerGuestId(int payerGuestId) {
        return invoiceRepository.findByPayerGuestId(payerGuestId);
    }

    // Ensures atomicity. If a complex operation fails mid-way, the database rolls back.
    @Transactional
    public boolean createInvoice(Invoice invoice) {
        return invoiceRepository.save(invoice) > 0;
    }

    public boolean updateInvoice(Invoice invoice) {
        return invoiceRepository.update(invoice) > 0;
    }
}
