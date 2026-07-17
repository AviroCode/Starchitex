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
        // Same fix as RoomMaintenanceService.createMaintenanceTicket: the DB
        // column defaults to 'Pending', but that default is skipped when the
        // column is explicitly set to null (a request body with no status
        // field), which trips the NOT NULL constraint. Force it in Java.
        RoomTask withStatus = task.status() != null ? task : new RoomTask(
                task.roomtaskId(),
                task.roomId(),
                task.assignedEmployeeId(),
                task.description(),
                task.assignedTime(),
                task.completedTime(),
                "Pending"
        );
        return roomTaskRepository.save(withStatus) > 0;
    }

    public boolean updateTask(RoomTask task) {
        return roomTaskRepository.update(task) > 0;
    }
}
