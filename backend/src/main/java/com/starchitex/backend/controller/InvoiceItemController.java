package com.starchitex.backend.controller;

import com.starchitex.backend.model.InvoiceItem;
import com.starchitex.backend.service.InvoiceItemService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/invoice-items")
public class InvoiceItemController {

    private final InvoiceItemService invoiceItemService;

    public InvoiceItemController(InvoiceItemService invoiceItemService) {
        this.invoiceItemService = invoiceItemService;
    }

    @GetMapping
    public List<InvoiceItem> getAllInvoiceItems() {
        return invoiceItemService.getAllInvoiceItems();
    }

    @GetMapping("/{invoiceItemId}")
    public ResponseEntity<InvoiceItem> getInvoiceItemById(@PathVariable int invoiceItemId) {
        return invoiceItemService.getInvoiceItemById(invoiceItemId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/invoice/{invoiceId}")
    public List<InvoiceItem> getInvoiceItemsByInvoiceId(@PathVariable int invoiceId) {
        return invoiceItemService.getInvoiceItemsByInvoiceId(invoiceId);
    }

    @PostMapping
    public ResponseEntity<String> createInvoiceItem(@RequestBody InvoiceItem item) {
        boolean isCreated = invoiceItemService.createInvoiceItem(item);
        if (isCreated) {
            return ResponseEntity.status(201).body("Invoice item created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create invoice item.");
        }
    }

    @PutMapping("/{invoiceItemId}")
    public ResponseEntity<String> updateInvoiceItem(@PathVariable int invoiceItemId, @RequestBody InvoiceItem item) {
        InvoiceItem itemToUpdate = new InvoiceItem(
                invoiceItemId,
                item.invoiceId(),
                item.roomId(),
                item.serviceId(),
                item.itemType(),
                item.quantity(),
                item.amount(),
                item.description()
        );

        boolean isUpdated = invoiceItemService.updateInvoiceItem(itemToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Invoice item updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update invoice item. Check if ID exists.");
        }
    }

    @DeleteMapping("/{invoiceItemId}")
    public ResponseEntity<String> deleteInvoiceItem(@PathVariable int invoiceItemId) {
        boolean isDeleted = invoiceItemService.deleteInvoiceItem(invoiceItemId);
        if (isDeleted) {
            return ResponseEntity.ok("Invoice item deleted successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to delete invoice item.");
        }
    }
}
