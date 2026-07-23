package com.tt.audit;

import com.tt.entity.AuditLog;
import com.tt.mapper.AuditLogMapper;
import com.tt.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

/**
 * 审计日志服务
 *
 * 记录 who / what / when / outcome（NIST AU-2/3/6/12）
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuditLogService {

    private final AuditLogMapper auditLogMapper;

    @Async
    public void log(String action, String targetType, Long targetId, String outcome, String detail) {
        try {
            AuditLog auditLog = new AuditLog();
            auditLog.setOperator(SecurityUtils.getCurrentUsername());
            auditLog.setAction(action);
            auditLog.setTargetType(targetType);
            auditLog.setTargetId(targetId);
            auditLog.setOutcome(outcome);
            auditLog.setDetail(detail);
            auditLog.setCreateTime(LocalDateTime.now());
            auditLogMapper.insert(auditLog);
        } catch (Exception e) {
            log.error("审计日志记录失败", e);
        }
    }

    public void logSuccess(String action, String targetType, Long targetId, String detail) {
        log(action, targetType, targetId, "SUCCESS", detail);
    }

    public void logFailure(String action, String targetType, Long targetId, String detail) {
        log(action, targetType, targetId, "FAILURE", detail);
    }
}
