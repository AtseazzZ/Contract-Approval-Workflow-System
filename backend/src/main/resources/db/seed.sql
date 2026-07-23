-- 种子数据
-- 密码均为 BCrypt 加密的 "123456"

-- 部门：研发部、运营部、市场部、财务部
INSERT INTO dept (id, name) VALUES
(1, '研发部'),
(2, '运营部'),
(3, '市场部'),
(4, '财务部');

-- 用户：U1-U4
-- U1 申请人，属研发部
-- U2 合同管理员，属研发部，负责 {研发部, 市场部}
-- U3 部门经理，属研发部
-- U4 领导，属财务部
INSERT INTO sys_user (id, username, password, real_name, primary_dept_id) VALUES
(1, 'u1', '$2a$10$L30PcrzM1BKXBZEL9SjJzOXviBPhnqvGQeEDw4Jab16KOtIVnhRpG', '张三(申请人)', 1),
(2, 'u2', '$2a$10$L30PcrzM1BKXBZEL9SjJzOXviBPhnqvGQeEDw4Jab16KOtIVnhRpG', '李四(合同管理员)', 1),
(3, 'u3', '$2a$10$L30PcrzM1BKXBZEL9SjJzOXviBPhnqvGQeEDw4Jab16KOtIVnhRpG', '王五(部门经理)', 1),
(4, 'u4', '$2a$10$L30PcrzM1BKXBZEL9SjJzOXviBPhnqvGQeEDw4Jab16KOtIVnhRpG', '赵六(领导)', 4);

-- 用户兼任部门：U2 兼任市场部
INSERT INTO user_dept (user_id, dept_id) VALUES
(2, 3);

-- 角色：申请人、合同管理员、部门经理、领导
-- 领导继承部门经理(parent_role_id=3)
INSERT INTO role (id, code, name, parent_role_id) VALUES
(1, 'APPLICANT', '申请人', NULL),
(2, 'CONTRACT_ADMIN', '合同管理员', NULL),
(3, 'DEPT_MANAGER', '部门经理', NULL),
(4, 'LEADER', '领导', 3);

-- 权限码
INSERT INTO permission (id, code, name) VALUES
(1, 'contract:create', '创建合同'),
(2, 'contract:view', '查看合同'),
(3, 'contract:edit', '编辑合同'),
(4, 'contract:withdraw', '撤回合同'),
(5, 'contract:process', '处理合同'),
(6, 'contract:approve', '审批合同'),
(7, 'contract:delete', '删除合同'),
(8, 'audit:view', '查看审计日志');

-- 角色-权限关联
-- U1 申请人: create, view, edit, withdraw
INSERT INTO role_permission (role_id, permission_id) VALUES
(1, 1), (1, 2), (1, 3), (1, 4);
-- U2 合同管理员: view, process
INSERT INTO role_permission (role_id, permission_id) VALUES
(2, 2), (2, 5);
-- U3 部门经理: view, approve
INSERT INTO role_permission (role_id, permission_id) VALUES
(3, 2), (3, 6);
-- U4 领导: view, approve, delete, audit（继承部门经理的 view, approve）
INSERT INTO role_permission (role_id, permission_id) VALUES
(4, 2), (4, 6), (4, 7), (4, 8);

-- 用户-角色关联
INSERT INTO user_role (user_id, role_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4);

-- 角色数据范围
-- U1 申请人: 仅本人
INSERT INTO role_data_scope (id, role_id, scope_type) VALUES
(1, 1, 'SELF');
-- U2 合同管理员: 自定义{研发部, 市场部}
INSERT INTO role_data_scope (id, role_id, scope_type) VALUES
(2, 2, 'CUSTOM');
INSERT INTO role_data_scope_dept (scope_id, dept_id) VALUES
(2, 1), (2, 3);
-- U3 部门经理: 本部门
INSERT INTO role_data_scope (id, role_id, scope_type) VALUES
(3, 3, 'DEPT');
-- U4 领导: 全部
INSERT INTO role_data_scope (id, role_id, scope_type) VALUES
(4, 4, 'ALL');

-- 审批流配置
INSERT INTO approval_flow_config (from_status, to_status, action, required_permission, required_role_code, sort_order) VALUES
('DRAFT',           'PENDING_ADMIN',    'SUBMIT',   'contract:create',   'APPLICANT',      1),
('DRAFT',           'WITHDRAWN',        'WITHDRAW', 'contract:withdraw', 'APPLICANT',      2),
('PENDING_ADMIN',   'PENDING_MANAGER',  'PROCESS',  'contract:process',  'CONTRACT_ADMIN', 3),
('PENDING_MANAGER', 'PENDING_LEADER',   'APPROVE',  'contract:approve',  'DEPT_MANAGER',   4),
('PENDING_LEADER',  'APPROVED',         'APPROVE',  'contract:approve',  'LEADER',         5),
('PENDING_ADMIN',   'DELETED',          'DELETE',   'contract:delete',   'LEADER',         6),
('PENDING_MANAGER', 'DELETED',          'DELETE',   'contract:delete',   'LEADER',         7),
('PENDING_LEADER',  'DELETED',          'DELETE',   'contract:delete',   'LEADER',         8);

-- 字段可见性配置
-- DRAFT / PENDING_ADMIN: 全部可见
-- PENDING_MANAGER: 银行账号脱敏
-- PENDING_LEADER: 隐藏条款明细、附件、备注，银行账号脱敏
-- APPROVED: 全部可见
INSERT INTO field_visibility_config (stage, field_name, visibility) VALUES
('PENDING_MANAGER', 'bank_account', 'MASKED'),
('PENDING_LEADER',  'clause_detail', 'HIDDEN'),
('PENDING_LEADER',  'attachment',    'HIDDEN'),
('PENDING_LEADER',  'remark',        'HIDDEN'),
('PENDING_LEADER',  'bank_account',  'MASKED');

-- 合同种子数据（分布在不同部门+不同审批节点）
INSERT INTO contract (id, contract_no, name, customer, amount, clause_detail, attachment, remark, bank_account, dept_id, applicant_id, status) VALUES
(1, 'HT20260701001', '研发部-办公设备采购合同', '联想科技', 150000.00, '采购100台笔记本电脑，单价1500元', '/files/ht001.pdf', '加急处理', '6225880123456789', 1, 1, 'PENDING_ADMIN'),
(2, 'HT20260701002', '市场部-广告投放合同', '字节跳动', 280000.00, '抖音信息流广告投放30天', '/files/ht002.pdf', '需市场部经理确认', '6225889876543210', 3, 1, 'PENDING_MANAGER'),
(3, 'HT20260701003', '研发部-云服务合同', '阿里云', 98000.00, 'ECS服务器年费', '/files/ht003.pdf', NULL, '6225880000111122', 1, 1, 'PENDING_LEADER'),
(4, 'HT20260701004', '研发部-内容外包合同', '某MCN机构', 56000.00, '月度内容产出50篇', NULL, '注意验收标准', '6225885555666677', 1, 1, 'DRAFT'),
(5, 'HT20260701005', '市场部-活动场地租赁', '某会展中心', 120000.00, '年会场地3天', '/files/ht005.pdf', NULL, '6225882222333344', 3, 1, 'APPROVED');
