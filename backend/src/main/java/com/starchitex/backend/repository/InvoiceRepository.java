package com.starchitex.backend.repository;

import com.starchitex.backend.model.Invoice;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class InvoiceRepository {

    private final JdbcTemplate jdbcTemplate;

    public InvoiceRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<Invoice> invoiceRowMapper = (rs, rowNum) -> new Invoice(
            rs.getInt("invoice_id"),
            rs.getInt("reservation_id"),
            rs.getInt("payer_guest_id"),
            rs.getObject("invoice_date", LocalDateTime.class),
            rs.getBigDecimal("sub_total"),
            rs.getBigDecimal("tax_amount"),
            rs.getBigDecimal("discount"),
            rs.getBigDecimal("total_amount"),
            rs.getString("status")
    );

    public List<Invoice> findAll() {
        String sql = "SELECT * FROM Invoice";
        return jdbcTemplate.query(sql, invoiceRowMapper);
    }

    public Optional<Invoice> findById(int invoiceId) {
        String sql = "SELECT * FROM Invoice WHERE invoice_id = ?";
        List<Invoice> invoices = jdbcTemplate.query(sql, invoiceRowMapper, invoiceId);
        return invoices.isEmpty() ? Optional.empty() : Optional.of(invoices.get(0));
    }

    public List<Invoice> findByReservationId(int reservationId) {
        String sql = "SELECT * FROM Invoice WHERE reservation_id = ?";
        return jdbcTemplate.query(sql, invoiceRowMapper, reservationId);
    }
    
    public List<Invoice> findByPayerGuestId(int payerGuestId) {
        String sql = "SELECT * FROM Invoice WHERE payer_guest_id = ?";
        return jdbcTemplate.query(sql, invoiceRowMapper, payerGuestId);
    }

    public int save(Invoice invoice) {
        String sql = "INSERT INTO Invoice (reservation_id, payer_guest_id, sub_total, tax_amount, discount, total_amount, status) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                invoice.reservationId(),
                invoice.payerGuestId(),
                invoice.subTotal(),
                invoice.taxAmount(),
                invoice.discount(),
                invoice.totalAmount(),
                invoice.status()
        );
    }

    public int update(Invoice invoice) {
        String sql = "UPDATE Invoice SET reservation_id = ?, payer_guest_id = ?, sub_total = ?, tax_amount = ?, discount = ?, total_amount = ?, status = ? " +
                     "WHERE invoice_id = ?";
        return jdbcTemplate.update(sql,
                invoice.reservationId(),
                invoice.payerGuestId(),
                invoice.subTotal(),
                invoice.taxAmount(),
                invoice.discount(),
                invoice.totalAmount(),
                invoice.status(),
                invoice.invoiceId()
        );
    }

    public void recalculateInvoiceTotal(int invoiceId) {
        String sql = "SELECT calculate_invoice_total(?)";
        jdbcTemplate.queryForObject(sql, java.math.BigDecimal.class, invoiceId);
    }

    private final RowMapper<com.starchitex.backend.model.MonthlyRevenueDTO> monthlyRevenueRowMapper = (rs, rowNum) -> new com.starchitex.backend.model.MonthlyRevenueDTO(
            rs.getInt("invoice_year"),
            rs.getInt("invoice_month"),
            rs.getInt("total_invoices"),
            rs.getBigDecimal("total_revenue")
    );

    // Queries the 'MonthlyRevenueReport' Materialized View
    public List<com.starchitex.backend.model.MonthlyRevenueDTO> getMonthlyRevenueReport() {
        String sql = "SELECT * FROM MonthlyRevenueReport";
        return jdbcTemplate.query(sql, monthlyRevenueRowMapper);
    }

    // Refreshes the Materialized View physical cache
    public void refreshMonthlyRevenueReport() {
        jdbcTemplate.execute("REFRESH MATERIALIZED VIEW MonthlyRevenueReport");
    }
}
