package com.starchitex.backend.repository;

import com.starchitex.backend.model.Guest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public class GuestRepository {

    private final JdbcTemplate jdbcTemplate;

    public GuestRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    // RowMapper specifically handling temporal LocalDate and LocalDateTime types
    private final RowMapper<Guest> guestRowMapper = (rs, rowNum) -> new Guest(
            rs.getInt("guest_id"),
            rs.getString("first_name"),
            rs.getString("last_name"),
            rs.getString("gender"),
            rs.getObject("date_of_birth", LocalDate.class),
            rs.getString("nationality"),
            rs.getString("passport_number"),
            rs.getString("phone_number"),
            rs.getString("email"),
            rs.getString("address"),
            rs.getObject("created_at", LocalDateTime.class)
    );

    public List<Guest> findAll() {
        String sql = "SELECT * FROM Guest";
        return jdbcTemplate.query(sql, guestRowMapper);
    }

    public Optional<Guest> findById(int id) {
        String sql = "SELECT * FROM Guest WHERE guest_id = ?";
        List<Guest> guests = jdbcTemplate.query(sql, guestRowMapper, id);
        return guests.isEmpty() ? Optional.empty() : Optional.of(guests.get(0));
    }

    public int save(Guest guest) {
        String sql = "INSERT INTO Guest (first_name, last_name, gender, date_of_birth, nationality, passport_number, phone_number, email, address) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
        return jdbcTemplate.update(sql,
                guest.firstName(),
                guest.lastName(),
                guest.gender(),
                guest.dateOfBirth(),
                guest.nationality(),
                guest.passportNumber(),
                guest.phoneNumber(),
                guest.email(),
                guest.address()
        );
    }

    public int update(Guest guest) {
        String sql = "UPDATE Guest SET first_name = ?, last_name = ?, gender = ?, date_of_birth = ?, nationality = ?, passport_number = ?, phone_number = ?, email = ?, address = ? " +
                     "WHERE guest_id = ?";
        return jdbcTemplate.update(sql,
                guest.firstName(),
                guest.lastName(),
                guest.gender(),
                guest.dateOfBirth(),
                guest.nationality(),
                guest.passportNumber(),
                guest.phoneNumber(),
                guest.email(),
                guest.address(),
                guest.guestId()
        );
    }
}
