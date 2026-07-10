package com.starchitex.backend.service;

import com.starchitex.backend.model.InvoiceItem;
import com.starchitex.backend.repository.InvoiceItemRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class InvoiceItemService {

    private final InvoiceItemRepository invoiceItemRepository;

    public InvoiceItemService(InvoiceItemRepository invoiceItemRepository) {
        this.invoiceItemRepository = invoiceItemRepository;
    }

    public List<InvoiceItem> getAllInvoiceItems() {
        return invoiceItemRepository.findAll();
    }

    public Optional<InvoiceItem> getInvoiceItemById(int invoiceItemId) {
        return invoiceItemRepository.findById(invoiceItemId);
    }

    public List<InvoiceItem> getInvoiceItemsByInvoiceId(int invoiceId) {
        return invoiceItemRepository.findByInvoiceId(invoiceId);
    }

    public boolean createInvoiceItem(InvoiceItem item) {
        return invoiceItemRepository.save(item) > 0;
    }

    public boolean updateInvoiceItem(InvoiceItem item) {
        return invoiceItemRepository.update(item) > 0;
    }

    public boolean deleteInvoiceItem(int invoiceItemId) {
        return invoiceItemRepository.delete(invoiceItemId) > 0;
    }
}
