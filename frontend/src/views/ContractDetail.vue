<template>
  <div class="contract-detail" v-loading="loading">
    <el-page-header @back="$router.back()" title="返回">
      <template #content>
        <span>合同详情 - {{ contract.contractNo }}</span>
      </template>
    </el-page-header>

    <el-row :gutter="16" style="margin-top: 16px;">
      <!-- 合同信息 -->
      <el-col :span="16">
        <el-card>
          <template #header>
            <div class="card-header">
              <span>合同信息</span>
              <el-tag :type="statusTagType(contract.status)" size="small">
                {{ statusLabel(contract.status) }}
              </el-tag>
            </div>
          </template>

          <el-descriptions :column="2" border>
            <el-descriptions-item label="合同编号">{{ contract.contractNo }}</el-descriptions-item>
            <el-descriptions-item label="合同名称">{{ contract.name }}</el-descriptions-item>
            <el-descriptions-item label="客户">{{ contract.customer }}</el-descriptions-item>
            <el-descriptions-item label="金额">
              {{ contract.amount ? '¥' + Number(contract.amount).toLocaleString() : '-' }}
            </el-descriptions-item>
            <el-descriptions-item label="归属部门">{{ contract.deptName }}</el-descriptions-item>
            <el-descriptions-item label="申请人">{{ contract.applicantName }}</el-descriptions-item>
            <el-descriptions-item label="创建时间">{{ contract.createTime }}</el-descriptions-item>
            <el-descriptions-item label="更新时间">{{ contract.updateTime }}</el-descriptions-item>

            <!-- 以下字段受字段可见性配置控制 -->
            <el-descriptions-item label="条款明细" :span="2">
              {{ contract.clauseDetail !== null ? contract.clauseDetail : '（已隐藏）' }}
            </el-descriptions-item>
            <el-descriptions-item label="附件" :span="2">
              <span v-if="contract.attachment !== null && contract.attachment !== undefined">
                {{ contract.attachment }}
              </span>
              <span v-else style="color: #909399;">（已隐藏）</span>
            </el-descriptions-item>
            <el-descriptions-item label="备注" :span="2">
              {{ contract.remark !== null ? contract.remark : '（已隐藏）' }}
            </el-descriptions-item>
            <el-descriptions-item label="对方银行账号" :span="2">
              {{ contract.bankAccount !== null ? contract.bankAccount : '（已隐藏）' }}
            </el-descriptions-item>
          </el-descriptions>

          <!-- 字段可见性提示 -->
          <el-alert
            v-if="fieldVisibilityNote"
            :title="fieldVisibilityNote"
            type="info"
            :closable="false"
            style="margin-top: 12px;"
          />
        </el-card>

        <!-- 审批操作区 -->
        <el-card style="margin-top: 16px;" v-if="contract.status && !isTerminal">
          <template #header>审批操作</template>

          <el-form>
            <el-form-item label="审批意见">
              <el-input
                v-model="approvalComment"
                type="textarea"
                :rows="3"
                placeholder="请输入审批意见（可选）"
              />
            </el-form-item>
            <el-form-item>
              <!-- 按钮显隐由 v-permission 指令控制（第2层强制） -->
              <!-- 后端 @PreAuthorize + 状态机门控是真正防线（第3层强制） -->
              <el-button
                v-if="contract.status === 'DRAFT'"
                v-permission="'contract:create'"
                type="primary"
                @click="doAction('submit')"
              >
                提交审批
              </el-button>

              <el-button
                v-if="contract.status === 'PENDING_ADMIN'"
                v-permission="'contract:process'"
                type="primary"
                @click="doAction('process')"
              >
                处理（合同管理员）
              </el-button>

              <el-button
                v-if="contract.status === 'PENDING_MANAGER' && hasRole('DEPT_MANAGER')"
                v-permission="'contract:approve'"
                type="primary"
                @click="doAction('approve')"
              >
                审批（部门经理）
              </el-button>

              <el-button
                v-if="contract.status === 'PENDING_LEADER' && hasRole('LEADER')"
                v-permission="'contract:approve'"
                type="primary"
                @click="doAction('approve')"
              >
                审批（领导）
              </el-button>

              <el-button
                v-if="contract.status === 'DRAFT'"
                v-permission="'contract:withdraw'"
                type="warning"
                @click="doAction('withdraw')"
              >
                撤回
              </el-button>

              <el-button
                v-permission="'contract:delete'"
                type="danger"
                @click="doAction('delete')"
              >
                删除
              </el-button>
            </el-form-item>
          </el-form>

          <el-alert
            title="安全说明：按钮显隐由 v-permission 指令控制（前端），后端 @PreAuthorize + 状态机门控是真正防线。可尝试用无权限账号直接调 API 验证。"
            type="warning"
            :closable="false"
            style="margin-top: 8px;"
          />
        </el-card>
      </el-col>

      <!-- 审批记录 -->
      <el-col :span="8">
        <el-card>
          <template #header>审批记录</template>
          <el-timeline v-if="records.length > 0">
            <el-timeline-item
              v-for="record in records"
              :key="record.id"
              :timestamp="record.createTime"
              :type="actionTagType(record.action)"
            >
              <div class="record-item">
                <strong>{{ actionLabel(record.action) }}</strong>
                <p>{{ statusLabel(record.fromStatus) }} → {{ statusLabel(record.toStatus) }}</p>
                <p>操作人：{{ record.operatorName }}</p>
                <p v-if="record.comment">意见：{{ record.comment }}</p>
              </div>
            </el-timeline-item>
          </el-timeline>
          <el-empty v-else description="暂无审批记录" />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  getContractDetail,
  getApprovalRecords,
  submitContract,
  processContract,
  approveContract,
  withdrawContract,
  deleteContract
} from '../api/contract'
import { useUserStore } from '../stores/user'

const route = useRoute()
const userStore = useUserStore()

const loading = ref(false)
const contract = ref({})
const records = ref([])
const approvalComment = ref('')

const isTerminal = computed(() => {
  const s = contract.value.status
  return s === 'APPROVED' || s === 'WITHDRAWN' || s === 'DELETED'
})

/** 检查当前用户是否有指定角色（精确匹配，不含继承） */
function hasRole(roleCode) {
  return userStore.roles && userStore.roles.includes(roleCode)
}

const fieldVisibilityNote = computed(() => {
  const status = contract.value.status
  if (!status) return ''
  const notes = {
    PENDING_MANAGER: '当前环节：部门经理审批 → 银行账号已脱敏',
    PENDING_LEADER: '当前环节：领导审批 → 条款明细/附件/备注已隐藏，银行账号已脱敏',
    DRAFT: '当前环节：草稿 → 全部字段可见',
    PENDING_ADMIN: '当前环节：合同管理员处理 → 全部字段可见',
    APPROVED: '当前环节：已通过 → 全部字段可见'
  }
  return notes[status] || ''
})

async function loadContract() {
  loading.value = true
  try {
    const res = await getContractDetail(route.params.id)
    contract.value = res.data
  } catch (e) {
    // 404 等已处理
  } finally {
    loading.value = false
  }
}

async function loadRecords() {
  try {
    const res = await getApprovalRecords(route.params.id)
    records.value = res.data || []
  } catch (e) {
    // 已处理
  }
}

async function doAction(action) {
  const actionLabels = {
    submit: '提交审批',
    process: '处理',
    approve: '审批',
    withdraw: '撤回',
    delete: '删除'
  }

  try {
    await ElMessageBox.confirm(
      `确定要执行"${actionLabels[action]}"操作吗？`,
      '确认',
      { confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning' }
    )
  } catch (e) {
    return
  }

  const id = route.params.id
  const comment = approvalComment.value
  try {
    switch (action) {
      case 'submit': await submitContract(id, comment); break
      case 'process': await processContract(id, comment); break
      case 'approve': await approveContract(id, comment); break
      case 'withdraw': await withdrawContract(id, comment); break
      case 'delete': await deleteContract(id, comment); break
    }
    ElMessage.success(actionLabels[action] + '成功')
    approvalComment.value = ''
    await loadContract()
    await loadRecords()
  } catch (e) {
    // 错误已处理
  }
}

function statusLabel(status) {
  const map = {
    DRAFT: '草稿',
    PENDING_ADMIN: '待合同管理员处理',
    PENDING_MANAGER: '待部门经理审批',
    PENDING_LEADER: '待领导审批',
    APPROVED: '已通过',
    WITHDRAWN: '已撤回',
    DELETED: '已删除'
  }
  return map[status] || status || ''
}

function statusTagType(status) {
  const map = {
    DRAFT: 'info',
    PENDING_ADMIN: '',
    PENDING_MANAGER: 'warning',
    PENDING_LEADER: 'danger',
    APPROVED: 'success',
    WITHDRAWN: 'info',
    DELETED: 'info'
  }
  return map[status] || ''
}

function actionLabel(action) {
  const map = { SUBMIT: '提交', PROCESS: '处理', APPROVE: '审批', WITHDRAW: '撤回', DELETE: '删除' }
  return map[action] || action
}

function actionTagType(action) {
  const map = { SUBMIT: 'primary', PROCESS: 'primary', APPROVE: 'success', WITHDRAW: 'warning', DELETE: 'danger' }
  return map[action] || ''
}

onMounted(() => {
  loadContract()
  loadRecords()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.record-item p {
  margin: 4px 0;
  font-size: 13px;
  color: #606266;
}
</style>
