<template>
  <el-container class="layout-container">
    <!-- 侧边栏 -->
    <el-aside width="220px" class="sidebar">
      <div class="logo">
        <el-icon size="24"><OfficeBuilding /></el-icon>
        <span>合同审批系统</span>
      </div>
      <el-menu
        :default-active="activeMenu"
        router
        class="sidebar-menu"
        background-color="#304156"
        text-color="#bfcbd9"
        active-text-color="#409EFF"
      >
        <template v-for="route in menuRoutes" :key="route.path">
          <el-menu-item
            v-if="!route.meta.hidden && hasRoutePermission(route)"
            :index="route.path"
          >
            <el-icon v-if="route.meta.icon"><component :is="route.meta.icon" /></el-icon>
            <span>{{ route.meta.title }}</span>
          </el-menu-item>
        </template>
      </el-menu>
    </el-aside>

    <el-container>
      <!-- 顶部导航 -->
      <el-header class="header">
        <div class="header-left">
          <span class="page-title">{{ currentTitle }}</span>
        </div>
        <div class="header-right">
          <el-tag type="info" size="small" class="role-tag">
            {{ userStore.primaryDeptName || '未知部门' }}
          </el-tag>
          <el-tag
            v-for="role in userStore.roles"
            :key="role"
            :type="roleTagType(role)"
            size="small"
            class="role-tag"
          >
            {{ roleLabel(role) }}
          </el-tag>
          <el-dropdown @command="handleCommand">
            <span class="user-info">
              <el-icon><User /></el-icon>
              {{ userStore.realName || userStore.username }}
              <el-icon><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <!-- 主内容区 -->
      <el-main class="main-content">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '../stores/user'
import { resetPermissionLoaded } from '../router'
import { ElMessageBox } from 'element-plus'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

// 菜单路由
const menuRoutes = computed(() => {
  const mainRoute = router.options.routes.find(r => r.path === '/')
  if (mainRoute && mainRoute.children) {
    return mainRoute.children.map(child => ({
      ...child,
      path: '/' + child.path
    }))
  }
  return []
})

const activeMenu = computed(() => {
  // 合同详情页高亮合同列表
  if (route.path.startsWith('/contract/detail')) {
    return '/contract/list'
  }
  return route.path
})

const currentTitle = computed(() => route.meta.title || '合同审批系统')

function hasRoutePermission(route) {
  if (!route.meta.permission) return true
  return userStore.hasPermission(route.meta.permission)
}

function roleLabel(code) {
  const map = {
    APPLICANT: '申请人',
    CONTRACT_ADMIN: '合同管理员',
    DEPT_MANAGER: '部门经理',
    LEADER: '领导'
  }
  return map[code] || code
}

function roleTagType(code) {
  const map = {
    APPLICANT: '',
    CONTRACT_ADMIN: 'success',
    DEPT_MANAGER: 'warning',
    LEADER: 'danger'
  }
  return map[code] || ''
}

async function handleCommand(command) {
  if (command === 'logout') {
    try {
      await ElMessageBox.confirm('确定要退出登录吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      })
      userStore.logout()
      resetPermissionLoaded()
      router.push('/login')
    } catch (e) {
      // 取消
    }
  }
}
</script>

<style scoped>
.layout-container {
  height: 100vh;
}
.sidebar {
  background-color: #304156;
  overflow: hidden;
}
.logo {
  height: 60px;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 20px;
  color: #fff;
  font-size: 16px;
  font-weight: bold;
  border-bottom: 1px solid #3a4a5b;
}
.sidebar-menu {
  border-right: none;
}
.header {
  background-color: #fff;
  border-bottom: 1px solid #e6e6e6;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
  height: 60px;
}
.header-left .page-title {
  font-size: 18px;
  font-weight: 600;
}
.header-right {
  display: flex;
  align-items: center;
  gap: 8px;
}
.role-tag {
  margin-right: 4px;
}
.user-info {
  display: flex;
  align-items: center;
  gap: 4px;
  cursor: pointer;
  color: #606266;
}
.main-content {
  background-color: #f0f2f5;
  padding: 20px;
  overflow-y: auto;
}
</style>
