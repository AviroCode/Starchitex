package com.starchitex.backend.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

@Component
public class JwtUtil {

    private static final Logger log = LoggerFactory.getLogger(JwtUtil.class);

    private final SecretKey key;
    private final long expirationTime = 86400000; // 24 hours in milliseconds

    public JwtUtil(@Value("${app.jwt.secret:}") String configuredSecret) {
        if (configuredSecret == null || configuredSecret.isBlank()) {
            log.warn("app.jwt.secret is not set — generating an ephemeral signing key. " +
                    "All existing sessions will be invalidated on every restart. " +
                    "Set JWT_SECRET (Base64-encoded, 256+ bits) for anything beyond local dev.");
            this.key = Keys.secretKeyFor(SignatureAlgorithm.HS256);
        } else {
            this.key = Keys.hmacShaKeyFor(Decoders.BASE64.decode(configuredSecret));
        }
    }

    public String generateToken(String username, int roleId, Integer branchId) {
        return Jwts.builder()
                .setSubject(username)
                .claim("roleId", roleId)
                .claim("branchId", branchId)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + expirationTime))
                .signWith(key)
                .compact();
    }

    public Claims extractClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    public String extractUsername(String token) {
        return extractClaims(token).getSubject();
    }
    
    public Integer extractBranchId(String token) {
        return extractClaims(token).get("branchId", Integer.class);
    }

    public int extractRoleId(String token) {
        return extractClaims(token).get("roleId", Integer.class);
    }

    public boolean isTokenValid(String token, String username) {
        final String extractedUsername = extractUsername(token);
        return (extractedUsername.equals(username) && !isTokenExpired(token));
    }

    private boolean isTokenExpired(String token) {
        return extractClaims(token).getExpiration().before(new Date());
    }
}
