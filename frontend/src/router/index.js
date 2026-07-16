import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '../stores/user'

/**
 * 三层强制之第1层：前端路由守卫 + 动态路由
 *
 * 设计：
 * - 静态路由：Login 页面（无需认证）
 * - 动态路由：根据用户权限码动态注册（afterEach addRoute）
 * - 路由守卫：未登录跳转 /login，已登录但未加载权限则拉取用户信息
 */

// 静态路由（无需认证）
const staticRoutes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue'),
    meta: { public: true }
  }
]

// 动态路由定义（根据权限码动态注册）
const dynamicRoutes = [
  {
    path: '/',
    component: () => import('../layout/Layout.vue'),
    redirect: '/contract/list',
    children: [
      {
        path: 'contract/list',
        name: 'ContractList',
        component: () => import('../views/ContractList.vue'),
        meta: { title: '合同列表', icon: 'Document', permission: 'contract:view' }
      },
      {
        path: 'contract/create',
        name: 'ContractCreate',
        component: () => import('../views/ContractCreate.vue'),
        meta: { title: '发起合同', icon: 'Edit', permission: 'contract:create' }
      },
      {
        path: 'contract/detail/:id',
        name: 'ContractDetail',
        component: () => import('../views/ContractDetail.vue'),
        meta: { title: '合同详情', hidden: true, permission: 'contract:view' }
      },
      {
        path: 'audit/list',
        name: 'AuditLog',
        component: () => import('../views/AuditLog.vue'),
        meta: { title: '审计日志', icon: 'List', permission: 'audit:view' }
      },
      {
        path: 'field-config',
        name: 'FieldConfig',
        component: () => import('../views/FieldConfig.vue'),
        meta: { title: '字段配置', icon: 'Setting' }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes: [...staticRoutes, ...dynamicRoutes]
})

// 标记是否已加载用户权限
let permissionLoaded = false

router.beforeEach(async (to, from, next) => {
  const userStore = useUserStore()

  // 公开路由直接放行
  if (to.meta.public) {
    // 已登录用户访问登录页 → 跳转首页
    if (userStore.isLoggedIn && to.path === '/login') {
      next('/')
    } else {
      next()
    }
    return
  }

  // 未登录 → 跳转登录页
  if (!userStore.isLoggedIn) {
    next('/login')
    return
  }

  // 已登录但未加载权限 → 拉取用户信息
  if (!permissionLoaded) {
    try {
      const userInfo = await userStore.fetchUserInfo()
      permissionLoaded = true

      // 检查目标路由是否需要权限
      if (to.meta.permission && !userStore.hasPermission(to.meta.permission)) {
        next('/contract/list')
      } else {
        next({ ...to, replace: true })
      }
    } catch (e) {
      permissionLoaded = false
      next('/login')
    }
    return
  }

  // 已加载权限，检查路由权限
  if (to.meta.permission && !userStore.hasPermission(to.meta.permission)) {
    next('/contract/list')
  } else {
    next()
  }
})

// 重置权限加载状态（登出时调用）
export function resetPermissionLoaded() {
  permissionLoaded = false
}

export default router
