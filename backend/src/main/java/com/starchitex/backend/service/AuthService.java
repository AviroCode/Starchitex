package com.starchitex.backend.service;

import com.starchitex.backend.model.Employee;
import com.starchitex.backend.model.EmployeeCredentials;
import com.starchitex.backend.model.Guest;
import com.starchitex.backend.model.GuestCredentials;
import com.starchitex.backend.repository.EmployeeCredentialsRepository;
import com.starchitex.backend.repository.EmployeeRepository;
import com.starchitex.backend.repository.GuestRepository;
import com.starchitex.backend.security.JwtUtil;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.Optional;

// Backs the public (permitAll) endpoints under /api/auth/** that need to
// write or read data before any JWT exists — see Documentation.md for the
// full design. Every DB table here is under FORCE ROW LEVEL SECURITY
// (RlsDataSource.java), and with no authenticated principal yet, a plain
// request would see app.current_branch_id/app.is_super_admin unset and get
// zero rows back or a policy rejection. Each method below issues
// `SET app.is_super_admin = 'true'` as its first statement, on the same
// connection Spring's @Transactional pins for the rest of the method — the
// exact pattern already trusted throughout database/seed/seed_data.sql and
// every database/tests/*.sql script. This is not a blanket bypass: each
// method only ever touches data keyed to what the caller themselves
// supplied (their own new guest record, or a lookup by an email they typed
// in), never arbitrary branch/guest data.
@Service
public class AuthService {

    private final JdbcTemplate jdbcTemplate;
    private final GuestRepository guestRepository;
    private final GuestCredentialsService guestCredentialsService;
    private final EmployeeRepository employeeRepository;
    private final EmployeeCredentialsRepository employeeCredentialsRepository;
    private final JwtUtil jwtUtil;
    private final String staffGoogleDomain;

    public AuthService(JdbcTemplate jdbcTemplate, GuestRepository guestRepository,
                        GuestCredentialsService guestCredentialsService, EmployeeRepository employeeRepository,
                        EmployeeCredentialsRepository employeeCredentialsRepository, JwtUtil jwtUtil,
                        @Value("${app.staff-google-domain}") String staffGoogleDomain) {
        this.jdbcTemplate = jdbcTemplate;
        this.guestRepository = guestRepository;
        this.guestCredentialsService = guestCredentialsService;
        this.employeeRepository = employeeRepository;
        this.employeeCredentialsRepository = employeeCredentialsRepository;
        this.jwtUtil = jwtUtil;
        this.staffGoogleDomain = staffGoogleDomain;
    }

    public record RegisterGuestRequest(String firstName, String lastName, String email, String phone, String password) {}

    @Transactional
    public String registerGuest(RegisterGuestRequest req) {
        jdbcTemplate.execute("SET app.is_super_admin = 'true'");

        Guest guest = new Guest(null, req.firstName(), req.lastName(), null, null, null, null, req.phone(), req.email(), null, null);
        int guestId = guestRepository.saveReturningId(guest);

        GuestCredentials credentials = new GuestCredentials(null, guestId, req.email(), req.password(), 10, null, null);
        guestCredentialsService.createCredentials(credentials);

        return jwtUtil.generateToken(req.email(), 10, null, guestId);
    }

    // SIMULATED Google sign-in: a real integration would use
    // spring-security-oauth2-client, redirect through Google's consent
    // screen, and verify a signed ID token instead of trusting a bare email
    // string from the request body. This stands in for that until a real
    // Google Cloud OAuth project exists — swapping it in only touches this
    // method (staff are still provisioned via EmployeesPage.jsx exactly as
    // today; this only replaces the password check for whoever's email
    // matches the org's domain).
    @Transactional
    public Optional<String> googleLogin(String email) {
        jdbcTemplate.execute("SET app.is_super_admin = 'true'");

        if (email == null || !email.toLowerCase(Locale.ROOT).endsWith("@" + staffGoogleDomain.toLowerCase(Locale.ROOT))) {
            return Optional.empty();
        }

        Optional<Employee> employee = employeeRepository.findByEmail(email);
        if (employee.isEmpty()) return Optional.empty();

        Optional<EmployeeCredentials> credentials = employeeCredentialsRepository.findById(employee.get().employeeId());
        if (credentials.isEmpty()) return Optional.empty();

        String token = jwtUtil.generateToken(credentials.get().username(), credentials.get().roleId(), employee.get().branchId(), null);
        return Optional.of(token);
    }
}
