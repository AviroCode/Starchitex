package com.starchitex.backend.service;

import com.starchitex.backend.model.Guest;
import com.starchitex.backend.repository.GuestRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class GuestService {

    private final GuestRepository guestRepository;

    public GuestService(GuestRepository guestRepository) {
        this.guestRepository = guestRepository;
    }

    public List<Guest> getAllGuests() {
        return guestRepository.findAll();
    }

    public Optional<Guest> getGuestById(int id) {
        return guestRepository.findById(id);
    }

    public boolean createGuest(Guest guest) {
        return guestRepository.save(guest) > 0;
    }

    public boolean updateGuest(Guest guest) {
        return guestRepository.update(guest) > 0;
    }
}
