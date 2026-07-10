package com.starchitex.backend.service;

import com.starchitex.backend.model.RoomTask;
import com.starchitex.backend.repository.RoomTaskRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class RoomTaskService {

    private final RoomTaskRepository roomTaskRepository;

    public RoomTaskService(RoomTaskRepository roomTaskRepository) {
        this.roomTaskRepository = roomTaskRepository;
    }

    public List<RoomTask> getAllTasks() {
        return roomTaskRepository.findAll();
    }

    public Optional<RoomTask> getTaskById(int roomtaskId) {
        return roomTaskRepository.findById(roomtaskId);
    }

    public List<RoomTask> getTasksByRoomId(int roomId) {
        return roomTaskRepository.findByRoomId(roomId);
    }

    public boolean createTask(RoomTask task) {
        return roomTaskRepository.save(task) > 0;
    }

    public boolean updateTask(RoomTask task) {
        return roomTaskRepository.update(task) > 0;
    }
}
