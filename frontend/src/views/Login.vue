<template>
  <div class="login-container">
    <el-card class="login-card">
      <template #header>
        <div class="login-header">
          <h2>企业级权限管理系统</h2>
          <p>合同审批流 Demo</p>
        </div>
      </template>

      <el-form :model="loginForm" @submit.prevent="handleLogin">
        <el-form-item>
          <el-input
            v-model="loginForm.username"
            placeholder="用户名"
            prefix-icon="User"
            size="large"
          />
        </el-form-item>
        <el-form-item>
          <el-input
            v-model="loginForm.password"
            type="password"
            placeholder="密码"
            prefix-icon="Lock"
            size="large"
            show-password
            @keyup.enter="handleLogin"
          />
        </el-form-item>
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            style="width: 100%"
            :loading="loading"
            @click="handleLogin"
          >
            登 录
          </el-button>
        </el-form-item>
      </el-form>

      <el-divider>快速登录（演示用）</el-divider>

      <div class="quick-login">
        <el-button
          v-for="user in quickUsers"
          :key="user.username"
          :type="user.type"
          @click="quickLogin(user)"
        >
          {{ user.label }}
        </el-button>
      </div>

      <div class="login-tip">
        <p>密码统一为：123456</p>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { login } from '../api/auth'
import { useUserStore } from '../stores/user'

const router = useRouter()
const userStore = useUserStore()
const loading = ref(false)

const loginForm = reactive({
  username: '',
  password: ''
})

const quickUsers = [
  { username: 'u1', label: 'U1 申请人', type: '' },
  { username: 'u2', label: 'U2 合同管理员', type: 'success' },
  { username: 'u3', label: 'U3 部门经理', type: 'warning' },
  { username: 'u4', label: 'U4 领导', type: 'danger' }
]

async function handleLogin() {
  if (!loginForm.username || !loginForm.password) {
    ElMessage.warning('请输入用户名和密码')
    return
  }
  loading.value = true
  try {
    const res = await login(loginForm)
    userStore.setToken(res.data.token)
    await userStore.fetchUserInfo()
    ElMessage.success('登录成功')
    router.push('/')
  } catch (e) {
    // 错误已由拦截器处理
  } finally {
    loading.value = false
  }
}

function quickLogin(user) {
  loginForm.username = user.username
  loginForm.password = '123456'
  handleLogin()
}
</script>

<style scoped>
.login-container {
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}
.login-card {
  width: 420px;
}
.login-header {
  text-align: center;
}
.login-header h2 {
  color: #303133;
  margin-bottom: 8px;
}
.login-header p {
  color: #909399;
  font-size: 14px;
}
.quick-login {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  justify-content: center;
}
.quick-login .el-button {
  margin: 0;
}
.login-tip {
  text-align: center;
  margin-top: 16px;
  color: #909399;
  font-size: 12px;
}
</style>
