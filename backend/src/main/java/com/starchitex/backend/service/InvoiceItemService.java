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
    private final InvoiceService invoiceService;

    public InvoiceItemService(InvoiceItemRepository invoiceItemRepository, InvoiceService invoiceService) {
        this.invoiceItemRepository = invoiceItemRepository;
        this.invoiceService = invoiceService;
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
        boolean saved = invoiceItemRepository.save(item) > 0;
        if (saved) invoiceService.recalculateInvoice(item.invoiceId());
        return saved;
    }

    @Transactional
    public boolean updateInvoiceItem(InvoiceItem item) {
        boolean updated = invoiceItemRepository.update(item) > 0;
        if (updated) invoiceService.recalculateInvoice(item.invoiceId());
        return updated;
    }

    @Transactional
    public boolean deleteInvoiceItem(int invoiceItemId) {
        // Fetch first so we know which invoice to recalculate after deletion
        InvoiceItem item = invoiceItemRepository.findById(invoiceItemId)
                .orElseThrow(() -> new IllegalArgumentException("InvoiceItem not found"));
        boolean deleted = invoiceItemRepository.delete(invoiceItemId) > 0;
        if (deleted) invoiceService.recalculateInvoice(item.invoiceId());
        return deleted;
    }
}
