-- 企业级权限管理系统（合同审批流）建表脚本
-- 注意：MySQL 中 user 是保留字，表名用 sys_user

DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS field_visibility_config;
DROP TABLE IF EXISTS approval_record;
DROP TABLE IF EXISTS approval_flow_config;
DROP TABLE IF EXISTS contract;
DROP TABLE IF EXISTS role_data_scope_dept;
DROP TABLE IF EXISTS role_data_scope;
DROP TABLE IF EXISTS role_permission;
DROP TABLE IF EXISTS user_role;
DROP TABLE IF EXISTS permission;
DROP TABLE IF EXISTS role;
DROP TABLE IF EXISTS user_dept;
DROP TABLE IF EXISTS sys_user;
DROP TABLE IF EXISTS dept;

-- 部门表（扁平，无上下级）
CREATE TABLE dept (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(64) NOT NULL,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
) COMMENT '部门表';

-- 用户表
CREATE TABLE sys_user (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(32) NOT NULL UNIQUE,
    password VARCHAR(128) NOT NULL,
    real_name VARCHAR(32),
    primary_dept_id BIGINT,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (primary_dept_id) REFERENCES dept(id)
) COMMENT '用户表';

-- 用户兼任部门（多对多）
CREATE TABLE user_dept (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    dept_id BIGINT NOT NULL,
    UNIQUE (user_id, dept_id),
    FOREIGN KEY (user_id) REFERENCES sys_user(id),
    FOREIGN KEY (dept_id) REFERENCES dept(id)
) COMMENT '用户兼任部门';

-- 角色表（含层级继承）
CREATE TABLE role (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(32) NOT NULL UNIQUE,
    name VARCHAR(64) NOT NULL,
    parent_role_id BIGINT DEFAULT NULL,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (parent_role_id) REFERENCES role(id)
) COMMENT '角色表';

-- 权限码词表
CREATE TABLE permission (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    code VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(64) NOT NULL,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
) COMMENT '权限码词表';

-- 用户-角色关联
CREATE TABLE user_role (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    UNIQUE (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES sys_user(id),
    FOREIGN KEY (role_id) REFERENCES role(id)
) COMMENT '用户-角色关联';

-- 角色-权限关联
CREATE TABLE role_permission (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    role_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    UNIQUE (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES role(id),
    FOREIGN KEY (permission_id) REFERENCES permission(id)
) COMMENT '角色-权限关联';

-- 角色数据范围配置（数据范围轴，与功能权限轴独立）
CREATE TABLE role_data_scope (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    role_id BIGINT NOT NULL UNIQUE,
    scope_type VARCHAR(16) NOT NULL COMMENT 'SELF/DEPT/CUSTOM/ALL',
    FOREIGN KEY (role_id) REFERENCES role(id)
) COMMENT '角色数据范围配置';

-- 自定义部门明细
CREATE TABLE role_data_scope_dept (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    scope_id BIGINT NOT NULL,
    dept_id BIGINT NOT NULL,
    UNIQUE (scope_id, dept_id),
    FOREIGN KEY (scope_id) REFERENCES role_data_scope(id),
    FOREIGN KEY (dept_id) REFERENCES dept(id)
) COMMENT '自定义部门明细';

-- 合同表
CREATE TABLE contract (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    contract_no VARCHAR(32) NOT NULL UNIQUE,
    name VARCHAR(128) NOT NULL,
    customer VARCHAR(64) NOT NULL,
    amount DECIMAL(18,2),
    clause_detail TEXT,
    attachment VARCHAR(255),
    remark TEXT,
    bank_account VARCHAR(64),
    dept_id BIGINT NOT NULL,
    applicant_id BIGINT NOT NULL,
    status VARCHAR(32) NOT NULL,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (dept_id) REFERENCES dept(id),
    FOREIGN KEY (applicant_id) REFERENCES sys_user(id)
) COMMENT '合同表';

-- 审批流配置表（状态转移规则，数据驱动）
CREATE TABLE approval_flow_config (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    from_status VARCHAR(32) NOT NULL,
    to_status VARCHAR(32) NOT NULL,
    action VARCHAR(32) NOT NULL,
    required_permission VARCHAR(64) NOT NULL,
    required_role_code VARCHAR(32),
    sort_order INT DEFAULT 0,
    UNIQUE (from_status, action)
) COMMENT '审批流配置表';

-- 审批记录表
CREATE TABLE approval_record (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    contract_id BIGINT NOT NULL,
    from_status VARCHAR(32),
    to_status VARCHAR(32) NOT NULL,
    action VARCHAR(32) NOT NULL,
    operator_id BIGINT NOT NULL,
    operator_name VARCHAR(32),
    comment TEXT,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (contract_id) REFERENCES contract(id)
) COMMENT '审批记录表';

-- 字段可见性配置表（流程环节级，非角色级）
CREATE TABLE field_visibility_config (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    stage VARCHAR(32) NOT NULL,
    field_name VARCHAR(64) NOT NULL,
    visibility VARCHAR(16) NOT NULL DEFAULT 'VISIBLE' COMMENT 'VISIBLE/MASKED/HIDDEN',
    UNIQUE (stage, field_name)
) COMMENT '字段可见性配置表';

-- 审计日志表
CREATE TABLE audit_log (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    operator VARCHAR(32) NOT NULL,
    action VARCHAR(64) NOT NULL,
    target_type VARCHAR(32),
    target_id BIGINT,
    outcome VARCHAR(16) NOT NULL COMMENT 'SUCCESS/FAILURE',
    detail TEXT,
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
) COMMENT '审计日志表';

CREATE INDEX idx_audit_target ON audit_log(target_type, target_id);
CREATE INDEX idx_audit_operator ON audit_log(operator);
CREATE INDEX idx_audit_time ON audit_log(create_time);
