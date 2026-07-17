package com.starchitex.backend.controller;

import com.starchitex.backend.model.AnalyticsSummaryDTO;
import com.starchitex.backend.model.MonthlyRevenueDTO;
import com.starchitex.backend.service.InvoiceService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/analytics")
public class AnalyticsController {

    private final InvoiceService invoiceService;

    public AnalyticsController(InvoiceService invoiceService) {
        this.invoiceService = invoiceService;
    }

    // Revenue is cross-branch business intelligence — admin-tier only, same
    // set of roles RlsDataSource already treats as is_super_admin (so these
    // queries correctly see every branch, not just one).
    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive')")
    @GetMapping("/summary")
    public AnalyticsSummaryDTO getSummary() {
        return invoiceService.getAnalyticsSummary();
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive')")
    @GetMapping("/monthly-revenue")
    public List<MonthlyRevenueDTO> getMonthlyRevenue() {
        return invoiceService.getMonthlyRevenueReport();
    }
}
