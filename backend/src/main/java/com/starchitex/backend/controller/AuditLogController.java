package com.starchitex.backend.controller;

import com.starchitex.backend.model.AuditLog;
import com.starchitex.backend.service.AuditLogService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/audit-logs")
public class AuditLogController {

    private final AuditLogService auditLogService;

    public AuditLogController(AuditLogService auditLogService) {
        this.auditLogService = auditLogService;
    }

    @GetMapping
    public List<AuditLog> getAllAuditLogs() {
        return auditLogService.getAllAuditLogs();
    }
    
    @GetMapping("/employee/{employeeId}")
    public List<AuditLog> getAuditLogsByEmployeeId(@PathVariable int employeeId) {
        return auditLogService.getAuditLogsByEmployeeId(employeeId);
    }
    
    @GetMapping("/table/{tableName}")
    public List<AuditLog> getAuditLogsByTableName(@PathVariable String tableName) {
        return auditLogService.getAuditLogsByTableName(tableName);
    }

}
