<template>
  <div class="field-config">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>字段可见性配置（数据驱动）</span>
          <el-button type="primary" size="small" @click="openAdd">新增配置</el-button>
        </div>
      </template>

      <el-alert
        title="此页面演示字段级可见性配置的数据驱动特性。修改配置后刷新合同详情即可看到效果（无需改代码、无需发版）。"
        type="info"
        :closable="false"
        style="margin-bottom: 16px;"
      />

      <el-table :data="tableData" v-loading="loading" stripe>
        <el-table-column prop="stage" label="审批环节" width="180">
          <template #default="{ row }">
            <el-tag size="small">{{ stageLabel(row.stage) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="fieldName" label="字段名" width="150" />
        <el-table-column prop="visibility" label="可见性" width="120">
          <template #default="{ row }">
            <el-tag :type="visibilityTagType(row.visibility)" size="small">
              {{ visibilityLabel(row.visibility) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120">
          <template #default="{ row }">
            <el-button size="small" link @click="openEdit(row)">编辑</el-button>
            <el-button size="small" link type="danger" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑对话框 -->
    <el-dialog
      v-model="dialogVisible"
      :title="editing ? '编辑配置' : '新增配置'"
      width="450px"
    >
      <el-form :model="form" label-width="100px">
        <el-form-item label="审批环节">
          <el-select v-model="form.stage" style="width: 100%" :disabled="editing">
            <el-option label="草稿" value="DRAFT" />
            <el-option label="待合同管理员处理" value="PENDING_ADMIN" />
            <el-option label="待部门经理审批" value="PENDING_MANAGER" />
            <el-option label="待领导审批" value="PENDING_LEADER" />
            <el-option label="已通过" value="APPROVED" />
          </el-select>
        </el-form-item>
        <el-form-item label="字段名">
          <el-select v-model="form.fieldName" style="width: 100%" :disabled="editing">
            <el-option label="条款明细" value="clauseDetail" />
            <el-option label="附件" value="attachment" />
            <el-option label="备注" value="remark" />
            <el-option label="对方银行账号" value="bankAccount" />
            <el-option label="金额" value="amount" />
            <el-option label="客户" value="customer" />
          </el-select>
        </el-form-item>
        <el-form-item label="可见性">
          <el-select v-model="form.visibility" style="width: 100%">
            <el-option label="可见" value="VISIBLE" />
            <el-option label="脱敏" value="MASKED" />
            <el-option label="隐藏" value="HIDDEN" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getFieldConfigList, addFieldConfig, updateFieldConfig, deleteFieldConfig } from '../api/contract'

const loading = ref(false)
const tableData = ref([])
const dialogVisible = ref(false)
const editing = ref(false)

const form = reactive({
  id: null,
  stage: '',
  fieldName: '',
  visibility: 'VISIBLE'
})

async function loadData() {
  loading.value = true
  try {
    const res = await getFieldConfigList()
    tableData.value = res.data || []
  } catch (e) {
    // 已处理
  } finally {
    loading.value = false
  }
}

function openAdd() {
  editing.value = false
  form.id = null
  form.stage = ''
  form.fieldName = ''
  form.visibility = 'VISIBLE'
  dialogVisible.value = true
}

function openEdit(row) {
  editing.value = true
  form.id = row.id
  form.stage = row.stage
  form.fieldName = row.fieldName
  form.visibility = row.visibility
  dialogVisible.value = true
}

async function handleSave() {
  if (!form.stage || !form.fieldName) {
    ElMessage.warning('请填写完整')
    return
  }
  try {
    if (editing.value) {
      await updateFieldConfig(form)
      ElMessage.success('修改成功')
    } else {
      await addFieldConfig(form)
      ElMessage.success('新增成功')
    }
    dialogVisible.value = false
    loadData()
  } catch (e) {
    // 已处理
  }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm('确定删除此配置吗？', '提示', { type: 'warning' })
    await deleteFieldConfig(row.id)
    ElMessage.success('删除成功')
    loadData()
  } catch (e) {
    // 取消或已处理
  }
}

function stageLabel(stage) {
  const map = {
    DRAFT: '草稿',
    PENDING_ADMIN: '待合同管理员处理',
    PENDING_MANAGER: '待部门经理审批',
    PENDING_LEADER: '待领导审批',
    APPROVED: '已通过'
  }
  return map[stage] || stage
}

function visibilityLabel(v) {
  const map = { VISIBLE: '可见', MASKED: '脱敏', HIDDEN: '隐藏' }
  return map[v] || v
}

function visibilityTagType(v) {
  const map = { VISIBLE: 'success', MASKED: 'warning', HIDDEN: 'danger' }
  return map[v] || ''
}

onMounted(() => {
  loadData()
})
</script>

<style scoped>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
