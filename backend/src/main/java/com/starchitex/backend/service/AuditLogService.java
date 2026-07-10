package com.starchitex.backend.service;

import com.starchitex.backend.model.AuditLog;
import com.starchitex.backend.repository.AuditLogRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;

    public AuditLogService(AuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    public List<AuditLog> getAllAuditLogs() {
        return auditLogRepository.findAll();
    }
    
    public List<AuditLog> getAuditLogsByEmployeeId(int employeeId) {
        return auditLogRepository.findByEmployeeId(employeeId);
    }
    
    public List<AuditLog> getAuditLogsByTableName(String tableName) {
        return auditLogRepository.findByTableName(tableName);
    }

    public boolean createAuditLog(AuditLog auditLog) {
        return auditLogRepository.save(auditLog) > 0;
    }
}
