package com.starchitex.backend.security;

import org.junit.jupiter.api.Test;

import java.util.Base64;

import static org.junit.jupiter.api.Assertions.*;

// Pure unit test — no Spring context, no database — exercising the signing
// key externalization added to JwtUtil (JWT_SECRET / app.jwt.secret).
class JwtUtilTest {

    @Test
    void tokenRoundTripsClaimsWithEphemeralKey() {
        JwtUtil jwtUtil = new JwtUtil("");

        String token = jwtUtil.generateToken("reception.bkk", 5, 1);

        assertEquals("reception.bkk", jwtUtil.extractUsername(token));
        assertEquals(5, jwtUtil.extractRoleId(token));
        assertEquals(1, jwtUtil.extractBranchId(token));
        assertTrue(jwtUtil.isTokenValid(token, "reception.bkk"));
        assertFalse(jwtUtil.isTokenValid(token, "someone.else"));
    }

    @Test
    void tokenRoundTripsClaimsWithConfiguredSecret() {
        String secret = Base64.getEncoder().encodeToString("a-test-only-secret-that-is-long-enough-for-hs256".getBytes());
        JwtUtil jwtUtil = new JwtUtil(secret);

        String token = jwtUtil.generateToken("admin.sys", 1, null);

        assertEquals("admin.sys", jwtUtil.extractUsername(token));
        assertEquals(1, jwtUtil.extractRoleId(token));
        assertNull(jwtUtil.extractBranchId(token));
        assertTrue(jwtUtil.isTokenValid(token, "admin.sys"));
    }

    @Test
    void differentInstancesWithDefaultSecretDoNotShareASigningKey() {
        JwtUtil first = new JwtUtil("");
        JwtUtil second = new JwtUtil("");

        String token = first.generateToken("demo.guest", 10, null);

        // Ephemeral keys are generated per-instance, so a token signed by one
        // JwtUtil cannot be parsed by another — this is exactly why JWT_SECRET
        // must be set for anything beyond a single local dev instance.
        assertThrows(Exception.class, () -> second.extractUsername(token));
    }
}
