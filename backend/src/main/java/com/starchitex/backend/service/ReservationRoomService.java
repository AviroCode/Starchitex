package com.starchitex.backend.service;

import com.starchitex.backend.model.ReservationRoom;
import com.starchitex.backend.model.Room;
import com.starchitex.backend.repository.ReservationRoomRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ReservationRoomService {

    private final ReservationRoomRepository reservationRoomRepository;

    public ReservationRoomService(ReservationRoomRepository reservationRoomRepository) {
        this.reservationRoomRepository = reservationRoomRepository;
    }

    public List<ReservationRoom> getAllReservationRooms() {
        return reservationRoomRepository.findAll();
    }

    public List<Room> getRoomsByReservationId(int reservationId) {
        return reservationRoomRepository.findRoomsByReservationId(reservationId);
    }

    public List<Integer> getReservationIdsByRoomId(int roomId) {
        return reservationRoomRepository.findReservationIdsByRoomId(roomId);
    }

    public boolean assignRoomToReservation(ReservationRoom reservationRoom) {
        return reservationRoomRepository.save(reservationRoom) > 0;
    }

    public boolean removeRoomFromReservation(int reservationId, int roomId) {
        return reservationRoomRepository.delete(reservationId, roomId) > 0;
    }
}
