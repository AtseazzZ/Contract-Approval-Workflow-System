/**
 * v-permission 指令
 *
 * 三层强制之第2层：按钮指令（移除 DOM）
 * - 检查当前用户是否有指定权限码
 * - 无权限时移除 DOM 元素（不是隐藏 display:none）
 * - 与后端共用一套权限码（如 contract:approve）
 *
 * 用法：
 *   <el-button v-permission="'contract:approve'">审批</el-button>
 *   <el-button v-permission="['contract:approve', 'contract:delete']">操作</el-button>  <!-- 满足任一即可 -->
 */
import { useUserStore } from '../stores/user'

export default {
  mounted(el, binding) {
    const userStore = useUserStore()
    const required = binding.value

    let hasPermission = false
    if (typeof required === 'string') {
      hasPermission = userStore.hasPermission(required)
    } else if (Array.isArray(required)) {
      hasPermission = userStore.hasAnyPermission(required)
    }

    if (!hasPermission) {
      // 移除 DOM，不是隐藏
      el.parentNode && el.parentNode.removeChild(el)
    }
  }
}
