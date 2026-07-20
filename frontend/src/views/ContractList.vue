<template>
  <div class="contract-list">
    <!-- 筛选栏 -->
    <el-card class="filter-card">
      <el-form :inline="true" :model="filter">
        <el-form-item label="状态">
          <el-select v-model="filter.status" placeholder="全部" clearable style="width: 180px">
            <el-option label="草稿" value="DRAFT" />
            <el-option label="待合同管理员处理" value="PENDING_ADMIN" />
            <el-option label="待部门经理审批" value="PENDING_MANAGER" />
            <el-option label="待领导审批" value="PENDING_LEADER" />
            <el-option label="已通过" value="APPROVED" />
            <el-option label="已撤回" value="WITHDRAWN" />
            <el-option label="已删除" value="DELETED" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="loadData">查询</el-button>
          <el-button @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 合同列表 -->
    <el-card>
      <template #header>
        <div class="card-header">
          <span>合同列表</span>
          <div>
            <span class="scope-hint">数据范围：{{ scopeHint }}</span>
            <el-button
              v-permission="'contract:create'"
              type="primary"
              size="small"
              @click="$router.push('/contract/create')"
            >
              发起合同
            </el-button>
          </div>
        </div>
      </template>

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="contractNo" label="合同编号" width="160" />
        <el-table-column prop="name" label="合同名称" min-width="180" show-overflow-tooltip />
        <el-table-column prop="customer" label="客户" width="140" />
        <el-table-column prop="deptName" label="归属部门" width="100" />
        <el-table-column prop="applicantName" label="申请人" width="100" />
        <el-table-column prop="amount" label="金额" width="120" align="right">
          <template #default="{ row }">
            {{ row.amount ? '¥' + Number(row.amount).toLocaleString() : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="status" label="当前节点" width="160">
          <template #default="{ row }">
            <el-tag :type="statusTagType(row.status)" size="small">
              {{ statusLabel(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button size="small" link @click="goDetail(row.id)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pagination">
        <el-pagination
          v-model:current-page="page.current"
          v-model:page-size="page.size"
          :total="page.total"
          :page-sizes="[10, 20, 50]"
          layout="total, sizes, prev, pager, next"
          @size-change="loadData"
          @current-change="loadData"
        />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { getContractList } from '../api/contract'
import { useUserStore } from '../stores/user'

const router = useRouter()
const userStore = useUserStore()

const loading = ref(false)
const tableData = ref([])
const page = reactive({ current: 1, size: 10, total: 0 })
const filter = reactive({ status: '' })

const scopeHint = computed(() => {
  const roles = userStore.roles
  if (roles.includes('LEADER')) return '全部合同'
  if (roles.includes('DEPT_MANAGER')) return '本部门合同'
  if (roles.includes('CONTRACT_ADMIN')) return '自定义部门集合'
  if (roles.includes('APPLICANT')) return '仅本人创建的合同'
  return '未知'
})

async function loadData() {
  loading.value = true
  try {
    const res = await getContractList({
      page: page.current,
      size: page.size,
      status: filter.status || undefined
    })
    tableData.value = res.data.records || []
    page.total = res.data.total || 0
  } catch (e) {
    // 已处理
  } finally {
    loading.value = false
  }
}

function resetFilter() {
  filter.status = ''
  page.current = 1
  loadData()
}

function goDetail(id) {
  router.push(`/contract/detail/${id}`)
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
  return map[status] || status
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

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.filter-card {
  margin-bottom: 16px;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.scope-hint {
  color: #909399;
  font-size: 13px;
  margin-right: 12px;
}
.pagination {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}
</style>
