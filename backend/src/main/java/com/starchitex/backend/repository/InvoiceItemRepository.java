package com.starchitex.backend.repository;

import com.starchitex.backend.model.InvoiceItem;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class InvoiceItemRepository {

    private final JdbcTemplate jdbcTemplate;

    public InvoiceItemRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    private final RowMapper<InvoiceItem> invoiceItemRowMapper = (rs, rowNum) -> {
        int rawRoomId = rs.getInt("room_id");
        Integer roomId = rs.wasNull() ? null : rawRoomId;
        int rawServiceId = rs.getInt("service_id");
        Integer serviceId = rs.wasNull() ? null : rawServiceId;
        return new InvoiceItem(
                rs.getInt("invoice_item_id"),
                rs.getInt("invoice_id"),
                roomId,
                serviceId,
                rs.getString("item_type"),
                rs.getInt("quantity"),
                rs.getBigDecimal("amount"),
                rs.getString("description")
        );
    };

    public List<InvoiceItem> findAll() {
        String sql = "SELECT * FROM InvoiceItem";
        return jdbcTemplate.query(sql, invoiceItemRowMapper);
    }

    public Optional<InvoiceItem> findById(int invoiceItemId) {
        String sql = "SELECT * FROM InvoiceItem WHERE invoice_item_id = ?";
        List<InvoiceItem> items = jdbcTemplate.query(sql, invoiceItemRowMapper, invoiceItemId);
        return items.isEmpty() ? Optional.empty() : Optional.of(items.get(0));
    }

    public List<InvoiceItem> findByInvoiceId(int invoiceId) {
        String sql = "SELECT * FROM InvoiceItem WHERE invoice_id = ?";
        return jdbcTemplate.query(sql, invoiceItemRowMapper, invoiceId);
    }

    public int save(InvoiceItem item) {
        String sql = "INSERT INTO InvoiceItem (invoice_id, room_id, service_id, item_type, quantity, amount, description) VALUES (?, ?, ?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                item.invoiceId(),
                item.roomId(),
                item.serviceId(),
                item.itemType(),
                item.quantity(),
                item.amount(),
                item.description()
        );
    }

    public int update(InvoiceItem item) {
        String sql = "UPDATE InvoiceItem SET invoice_id = ?, room_id = ?, service_id = ?, item_type = ?, quantity = ?, amount = ?, description = ? WHERE invoice_item_id = ?";
        return jdbcTemplate.update(sql,
                item.invoiceId(),
                item.roomId(),
                item.serviceId(),
                item.itemType(),
                item.quantity(),
                item.amount(),
                item.description(),
                item.invoiceItemId()
        );
    }

    public int delete(int invoiceItemId) {
        String sql = "DELETE FROM InvoiceItem WHERE invoice_item_id = ?";
        return jdbcTemplate.update(sql, invoiceItemId);
    }
}
