package com.starchitex.backend.controller;

import com.starchitex.backend.model.EmployeeCredentials;
import com.starchitex.backend.model.GuestCredentials;
import com.starchitex.backend.repository.EmployeeCredentialsRepository;
import com.starchitex.backend.repository.GuestCredentialsRepository;
import com.starchitex.backend.security.JwtUtil;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthenticationManager authenticationManager;
    private final JwtUtil jwtUtil;
    private final EmployeeCredentialsRepository employeeRepo;
    private final GuestCredentialsRepository guestRepo;

    public AuthController(AuthenticationManager authenticationManager, JwtUtil jwtUtil, EmployeeCredentialsRepository employeeRepo, GuestCredentialsRepository guestRepo) {
        this.authenticationManager = authenticationManager;
        this.jwtUtil = jwtUtil;
        this.employeeRepo = employeeRepo;
        this.guestRepo = guestRepo;
    }

    @PostMapping("/login")
    public ResponseEntity<String> login(@RequestBody LoginRequest request) {
        try {
            Authentication auth = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.username(), request.password())
            );

            // Fetch the user's roleId from the DB to embed in the token
            int roleId = -1;
            
            Optional<EmployeeCredentials> empOpt = employeeRepo.findByUsername(request.username());
            if (empOpt.isPresent()) {
                roleId = empOpt.get().roleId();
            } else {
                Optional<GuestCredentials> guestOpt = guestRepo.findByUsername(request.username());
                if (guestOpt.isPresent()) {
                    roleId = guestOpt.get().roleId();
                }
            }

            // Generate JWT
            String token = jwtUtil.generateToken(request.username(), roleId);
            return ResponseEntity.ok(token);

        } catch (Exception e) {
            return ResponseEntity.status(401).body("Invalid username or password");
        }
    }

    // Inner record for request body mapping
    public record LoginRequest(String username, String password) {}
}
