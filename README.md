#  企业级权限管理系统（合同审批流）

> Demo | 技术栈：Spring Boot 2.7 + Vue 3 + MyBatis-Plus + MySQL

## 快速启动

### 前置要求
- JDK 8
- Maven 3.6+
- Node.js 16+
- MySQL 8.0（root 密码 `123456`，端口 3306）

### 1. 启动后端

```bash
cd backend
mvn spring-boot:run
```
- 服务端口：`8081`，context-path：`/api`
- 首次启动自动建库建表 + 导入种子数据（`schema.sql` / `seed.sql`）

### 2. 启动前端

```bash
cd frontend
npm install
npm run dev
```
- 访问地址：`http://localhost:5173`
- Vite 代理已配置 `/api` → `http://localhost:8081`

### 3. 登录

| 用户 | 密码 | 角色 | 数据范围 |
|------|------|------|----------|
| u1 | 123456 | 申请人(APPLICANT) | SELF 仅本人 |
| u2 | 123456 | 合同管理员(CONTRACT_ADMIN) | CUSTOM {研发部, 市场部} |
| u3 | 123456 | 部门经理(DEPT_MANAGER) | DEPT 本部门(研发部) |
| u4 | 123456 | 领导(LEADER，继承DEPT_MANAGER) | ALL 全部 |

---

## 核心设计

### 1. RBAC + 角色继承
- 角色表 `role` 通过 `parent_role_id` 实现继承链
- LEADER 继承 DEPT_MANAGER：递归 CTE 查询所有祖先角色权限，取并集
- 示例：U4(LEADER) 自动拥有 DEPT_MANAGER 的 `contract:approve` 权限

### 2. 两轴分离（功能权限 × 数据范围）
- **功能权限**：`role_permission` 表，控制"能做什么"（如 contract:approve）
- **数据范围**：`role_data_scope` 表，控制"能看哪些数据"（SELF/DEPT/CUSTOM/ALL）
- 两轴独立配置，多角色取并集
- 数据范围解析为 SQL WHERE 条件，施加在 Mapper 层

### 3. 三层权限强制
| 层次 | 技术 | 作用 |
|------|------|------|
| 前端 | v-permission 指令（DOM 移除） | 按钮可见性 |
| 后端方法级 | @PreAuthorize("hasAuthority('xxx')") | 功能权限校验 |
| 后端数据级 | DataScopeResolver → SQL WHERE | 数据范围过滤 |

### 4. 审批流状态机
- 状态转移配置在 `approval_flow_config` 表（数据驱动，非硬编码）
- 三重门控：数据范围 → 状态机 → 功能权限 + 角色门控
- 流程：DRAFT → PENDING_ADMIN → PENDING_MANAGER → PENDING_LEADER → APPROVED
- 节点顺序强制：U3 不能跳过 U2 直接审批（状态不匹配 → 403）

### 5. IDOR 防护
- 越权访问合同 → 返回 **404**（非 403），不泄露资源存在性
- 实现：`selectByIdWithScope(id, scopeCondition)` 查不到即 404

### 6. 字段级可见性
- 配置在 `field_visibility_config` 表，按**流程环节**（非角色）配置
- 三种模式：VISIBLE / MASKED（脱敏，如 62****89）/ HIDDEN（字段从 JSON 消失）
- 示例：PENDING_LEADER 阶段隐藏 clause_detail、attachment、remark，bank_account 脱敏
- 数据驱动：修改配置后刷新缓存即时生效

### 7. 审计日志
- AOP 自动记录：谁(who)、做了什么(what)、何时(when)、结果(outcome)
- 覆盖所有审批操作（成功/失败均记录）

---

## 验收场景

| # | 场景 | 验证方法 |
|---|------|----------|
| 1 | U1(SELF) 仅看到本人合同 | U1 登录 → 合同列表，5条均为 applicant_id=1 |
| 2 | U2(CUSTOM) 看到{研发,市场}合同 | U2 登录 → 合同列表，dept_id ∈ {1,3} |
| 3 | U3(DEPT) 仅看到研发部合同 | U3 登录 → 合同列表，dept_id=1 |
| 4 | U4(ALL) 看到全部合同 | U4 登录 → 合同列表，所有部门 |
| 5 | 按钮可见性 | U1 无"审批"按钮，U4 有"审批"按钮（v-permission DOM移除）|
| 6 | 审批流 U1→U2→U3→U4 | 对合同4依次执行 SUBMIT→PROCESS→APPROVE→APPROVE |
| 7 | 节点顺序强制 | U3 对 PENDING_ADMIN 合同执行 APPROVE → 403 |
| 8 | IDOR 防护 | U3 访问市场部合同 → 404（非403） |
| 9 | 字段可见性 | PENDING_MANAGER 阶段 bank_account 脱敏；PENDING_LEADER 阶段 clause_detail 隐藏 |
| 10 | 审计日志 | U4 可查看审计日志；U1 无权限 → 403 |

---

## 项目结构

```
ERM/
├── backend/                    # Spring Boot 后端
│   ├── src/main/java/com/tt/
│   │   ├── config/             # SecurityConfig（deny-by-default + JWT）
│   │   ├── controller/         # ContractController, AuthController, AuditLogController...
│   │   ├── entity/             # Contract, User, Role, Permission...
│   │   ├── mapper/             # ContractMapper(数据范围SQL), RoleMapper(递归CTE)...
│   │   ├── permission/         # DataScopeResolver, FunctionPermissionResolver
│   │   ├── workflow/           # ApprovalFlowService（状态机+三重门控）
│   │   ├── field/              # FieldVisibilityService（字段可见性）
│   │   ├── audit/              # AuditLogService + AOP
│   │   └── security/           # JwtUtils, JwtAuthFilter, SecurityUtils
│   └── src/main/resources/
│       ├── application.yml
│       └── db/                 # schema.sql(建表) + seed.sql(种子数据)
│
├── frontend/                   # Vue 3 前端
│   ├── src/
│   │   ├── api/                # axios 封装 + JWT 拦截器
│   │   ├── directives/         # v-permission（DOM 移除）
│   │   ├── router/             # 动态路由 + 权限守卫
│   │   ├── stores/             # Pinia（token/permissions/roles）
│   │   └── views/              # ContractList, ContractDetail, AuditLog, FieldConfig...
│   └── vite.config.js          # 代理 /api → :8081
│
├── design.md                   # 面试题目
├── 架构设计.md                  # 架构设计文档
└── 需求理解.md                  # 需求分析文档
```

---

## 技术选型说明

> 原题要求 Spring Boot 3，因本机仅有 JDK 8，降级为 Spring Boot 2.7.3（API 完全兼容）。

| 组件 | 版本 | 说明 |
|------|------|------|
| Spring Boot | 2.7.3 | Java 8 兼容 |
| Spring Security | 5.7 | @PreAuthorize 方法级鉴权 |
| MyBatis-Plus | 3.5.3.1 | 分页插件 + 代码简化 |
| JJWT | 0.11.5 | 无状态 JWT 认证 |
| Vue | 3.4 | Composition API |
| Element Plus | 2.5 | UI 组件库 |
| Pinia | 2.1 | 状态管理 |
| MySQL | 8.0 | createDatabaseIfNotExist=true |
