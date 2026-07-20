<template>
  <div class="contract-create">
    <el-page-header @back="$router.back()" title="返回">
      <template #content>发起合同</template>
    </el-page-header>

    <el-card style="margin-top: 16px;">
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="120px"
        style="max-width: 700px;"
      >
        <el-form-item label="合同编号" prop="contractNo">
          <el-input v-model="form.contractNo" placeholder="留空则自动生成" />
        </el-form-item>
        <el-form-item label="合同名称" prop="name">
          <el-input v-model="form.name" placeholder="请输入合同名称" />
        </el-form-item>
        <el-form-item label="客户" prop="customer">
          <el-input v-model="form.customer" placeholder="请输入客户/对方名称" />
        </el-form-item>
        <el-form-item label="金额" prop="amount">
          <el-input-number v-model="form.amount" :min="0" :precision="2" style="width: 200px" />
        </el-form-item>
        <el-form-item label="归属部门" prop="deptId">
          <el-select v-model="form.deptId" placeholder="选择归属部门" style="width: 200px">
            <el-option
              v-for="dept in deptList"
              :key="dept.id"
              :label="dept.name"
              :value="dept.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="条款明细">
          <el-input v-model="form.clauseDetail" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="附件">
          <el-input v-model="form.attachment" placeholder="附件路径（如 /files/xxx.pdf）" />
        </el-form-item>
        <el-form-item label="对方银行账号">
          <el-input v-model="form.bankAccount" placeholder="对方银行账号" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="loading" @click="handleSubmit">创建合同</el-button>
          <el-button @click="$router.back()">取消</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { createContract, getDeptList } from '../api/contract'
import { useUserStore } from '../stores/user'

const router = useRouter()
const userStore = useUserStore()

const formRef = ref()
const loading = ref(false)
const deptList = ref([])

const form = reactive({
  contractNo: '',
  name: '',
  customer: '',
  amount: 0,
  deptId: null,
  clauseDetail: '',
  attachment: '',
  bankAccount: '',
  remark: ''
})

const rules = {
  name: [{ required: true, message: '请输入合同名称', trigger: 'blur' }],
  customer: [{ required: true, message: '请输入客户', trigger: 'blur' }]
}

async function loadDepts() {
  try {
    const res = await getDeptList()
    deptList.value = res.data || []
    // 默认选用户主部门
    // 注意：主部门 ID 从后端 UserInfo 获取不到，这里让用户自己选
  } catch (e) {
    // 已处理
  }
}

async function handleSubmit() {
  try {
    await formRef.value.validate()
  } catch (e) {
    return
  }

  loading.value = true
  try {
    const res = await createContract(form)
    ElMessage.success('合同创建成功')
    router.push(`/contract/detail/${res.data.id}`)
  } catch (e) {
    // 已处理
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadDepts()
})
</script>
