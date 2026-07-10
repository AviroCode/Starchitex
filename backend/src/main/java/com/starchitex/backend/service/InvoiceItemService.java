package com.starchitex.backend.service;

import com.starchitex.backend.model.InvoiceItem;
import com.starchitex.backend.repository.InvoiceItemRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    @Transactional
    public boolean createInvoiceItem(InvoiceItem item) {
        // Recalculation of invoice totals is handled by trg_recalculate_invoice_total_on_item_change (AFTER INSERT/UPDATE/DELETE)
        return invoiceItemRepository.save(item) > 0;
    }

    @Transactional
    public boolean updateInvoiceItem(InvoiceItem item) {
        return invoiceItemRepository.update(item) > 0;
    }

    @Transactional
    public boolean deleteInvoiceItem(int invoiceItemId) {
        return invoiceItemRepository.delete(invoiceItemId) > 0;
    }
}
