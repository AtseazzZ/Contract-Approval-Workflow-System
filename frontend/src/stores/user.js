import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { getUserInfo } from '../api/auth'

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('token') || '')
  const userId = ref(null)
  const username = ref('')
  const realName = ref('')
  const permissions = ref(new Set())
  const roles = ref([])
  const primaryDeptName = ref('')

  const isLoggedIn = computed(() => !!token.value)

  function hasPermission(code) {
    return permissions.value.has(code)
  }

  function hasAnyPermission(codes) {
    return codes.some(code => permissions.value.has(code))
  }

  function setToken(t) {
    token.value = t
    localStorage.setItem('token', t)
  }

  async function fetchUserInfo() {
    try {
      const res = await getUserInfo()
      const data = res.data
      userId.value = data.userId
      username.value = data.username
      realName.value = data.realName
      permissions.value = new Set(data.permissions || [])
      roles.value = data.roles || []
      primaryDeptName.value = data.primaryDeptName || ''
      return data
    } catch (e) {
      logout()
      throw e
    }
  }

  function logout() {
    token.value = ''
    userId.value = null
    username.value = ''
    realName.value = ''
    permissions.value = new Set()
    roles.value = []
    localStorage.removeItem('token')
  }

  return {
    token, userId, username, realName, permissions, roles, primaryDeptName,
    isLoggedIn, hasPermission, hasAnyPermission, setToken, fetchUserInfo, logout
  }
})
