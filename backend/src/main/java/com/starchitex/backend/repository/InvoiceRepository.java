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

    public Optional<Invoice> findByIdForUpdate(int invoiceId) {
        String sql = "SELECT * FROM Invoice WHERE invoice_id = ? FOR UPDATE";
        List<Invoice> invoices = jdbcTemplate.query(sql, invoiceRowMapper, invoiceId);
        return invoices.isEmpty() ? Optional.empty() : Optional.of(invoices.get(0));
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

    // Closes the loop on the 'Refunded' status value, which the CHECK
    // constraint has always allowed but nothing previously set. This records
    // that staff processed a refund outside the app (no real payment
    // gateway integration exists to reverse a charge through) — it doesn't
    // move any money itself.
    public int markRefunded(int invoiceId) {
        String sql = "UPDATE Invoice SET status = 'Refunded' WHERE invoice_id = ?";
        return jdbcTemplate.update(sql, invoiceId);
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

    // Occupancy Rate (today) = occupiedToday / totalRooms.
    // ADR (Average Daily Rate, this month) = revenueThisMonth / roomNightsSoldThisMonth.
    // RevPAR (Revenue Per Available Room, this month) = revenueThisMonth / (totalRooms * daysElapsedThisMonth).
    private static final String ANALYTICS_SUMMARY_SQL = """
        WITH total_rooms AS (
            SELECT COUNT(*) AS n FROM Room
        ), occupied_today AS (
            SELECT COUNT(*) AS n FROM RoomAvailability
            WHERE status = 'Occupied' AND calendar_date = CURRENT_DATE
        ), room_nights_month AS (
            SELECT COUNT(*) AS n FROM RoomAvailability
            WHERE status = 'Occupied'
              AND calendar_date >= date_trunc('month', CURRENT_DATE)
              AND calendar_date < date_trunc('month', CURRENT_DATE) + INTERVAL '1 month'
        ), revenue_month AS (
            SELECT COALESCE(total_revenue, 0) AS n FROM MonthlyRevenueReport
            WHERE invoice_year = EXTRACT(YEAR FROM CURRENT_DATE) AND invoice_month = EXTRACT(MONTH FROM CURRENT_DATE)
        )
        SELECT
            total_rooms.n AS total_rooms,
            occupied_today.n AS occupied_today,
            CASE WHEN total_rooms.n > 0 THEN occupied_today.n::numeric / total_rooms.n ELSE 0 END AS occupancy_rate_today,
            room_nights_month.n AS room_nights_this_month,
            COALESCE((SELECT n FROM revenue_month), 0) AS revenue_this_month,
            CASE WHEN room_nights_month.n > 0 THEN COALESCE((SELECT n FROM revenue_month), 0) / room_nights_month.n ELSE 0 END AS adr,
            CASE WHEN total_rooms.n > 0 THEN COALESCE((SELECT n FROM revenue_month), 0) / (total_rooms.n * EXTRACT(DAY FROM CURRENT_DATE)) ELSE 0 END AS revpar
        FROM total_rooms, occupied_today, room_nights_month
        """;

    public com.starchitex.backend.model.AnalyticsSummaryDTO getAnalyticsSummary() {
        return jdbcTemplate.queryForObject(ANALYTICS_SUMMARY_SQL, (rs, rowNum) -> new com.starchitex.backend.model.AnalyticsSummaryDTO(
                rs.getInt("total_rooms"),
                rs.getInt("occupied_today"),
                rs.getBigDecimal("occupancy_rate_today"),
                rs.getInt("room_nights_this_month"),
                rs.getBigDecimal("revenue_this_month"),
                rs.getBigDecimal("adr"),
                rs.getBigDecimal("revpar")
        ));
    }
}
