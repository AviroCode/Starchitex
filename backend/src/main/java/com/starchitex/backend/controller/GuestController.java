package com.starchitex.backend.controller;

import com.starchitex.backend.model.Guest;
import com.starchitex.backend.service.GuestService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;

import java.util.List;

@RestController
@RequestMapping("/api/guests")
public class GuestController {

    private final GuestService guestService;

    public GuestController(GuestService guestService) {
        this.guestService = guestService;
    }

    // Guest is now RLS-protected (chain-wide directory: any staff member, any
    // branch, or the guest themself) -- these checks are defense-in-depth only.
    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @GetMapping
    public List<Guest> getAllGuests() {
        return guestService.getAllGuests();
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null or authentication.principal.guestId == #id")
    @GetMapping("/{id}")
    public ResponseEntity<Guest> getGuestById(@PathVariable int id) {
        return guestService.getGuestById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null")
    @PostMapping
    public ResponseEntity<String> createGuest(@RequestBody Guest guest) {
        boolean isCreated = guestService.createGuest(guest);
        if (isCreated) {
            return ResponseEntity.status(201).body("Guest created successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to create guest.");
        }
    }

    @PreAuthorize("hasAnyRole('System Administrator', 'Hotel Owner', 'Sales Executive') or authentication.principal.branchId != null or authentication.principal.guestId == #id")
    @PutMapping("/{id}")
    public ResponseEntity<String> updateGuest(@PathVariable int id, @RequestBody Guest guest) {
        Guest guestToUpdate = new Guest(
                id,
                guest.firstName(),
                guest.lastName(),
                guest.gender(),
                guest.dateOfBirth(),
                guest.nationality(),
                guest.passportNumber(),
                guest.phoneNumber(),
                guest.email(),
                guest.address(),
                guest.createdAt()
        );

        boolean isUpdated = guestService.updateGuest(guestToUpdate);
        if (isUpdated) {
            return ResponseEntity.ok("Guest updated successfully!");
        } else {
            return ResponseEntity.status(400).body("Failed to update guest. Check if ID exists.");
        }
    }
}
