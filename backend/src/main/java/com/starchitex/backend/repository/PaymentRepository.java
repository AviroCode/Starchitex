package com.starchitex.backend.repository;

import com.starchitex.backend.model.Payment;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class PaymentRepository {

    private final JdbcTemplate jdbcTemplate;

    public PaymentRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<Payment> paymentRowMapper = (rs, rowNum) -> new Payment(
            rs.getInt("payment_id"),
            rs.getInt("invoice_id"),
            rs.getObject("payment_date", LocalDateTime.class),
            rs.getBigDecimal("amount"),
            rs.getString("payment_method"),
            rs.getString("transaction_ref")
    );

    public List<Payment> findAll() {
        String sql = "SELECT * FROM Payment";
        return jdbcTemplate.query(sql, paymentRowMapper);
    }

    public Optional<Payment> findById(int paymentId) {
        String sql = "SELECT * FROM Payment WHERE payment_id = ?";
        List<Payment> payments = jdbcTemplate.query(sql, paymentRowMapper, paymentId);
        return payments.isEmpty() ? Optional.empty() : Optional.of(payments.get(0));
    }

    public List<Payment> findByInvoiceId(int invoiceId) {
        String sql = "SELECT * FROM Payment WHERE invoice_id = ?";
        return jdbcTemplate.query(sql, paymentRowMapper, invoiceId);
    }

    public int save(Payment payment) {
        String sql = "INSERT INTO Payment (invoice_id, amount, payment_method, transaction_ref) VALUES (?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                payment.invoiceId(),
                payment.amount(),
                payment.paymentMethod(),
                payment.transactionRef()
        );
    }

    public int update(Payment payment) {
        String sql = "UPDATE Payment SET invoice_id = ?, amount = ?, payment_method = ?, transaction_ref = ? WHERE payment_id = ?";
        return jdbcTemplate.update(sql,
                payment.invoiceId(),
                payment.amount(),
                payment.paymentMethod(),
                payment.transactionRef(),
                payment.paymentId()
        );
    }
}
