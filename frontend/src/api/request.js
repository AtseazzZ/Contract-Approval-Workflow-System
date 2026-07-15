import axios from 'axios'
import { ElMessage } from 'element-plus'

const request = axios.create({
  baseURL: '/api',
  timeout: 10000
})

// 请求拦截器：附加 JWT
request.interceptors.request.use(
  config => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => Promise.reject(error)
)

// 响应拦截器：统一处理错误
request.interceptors.response.use(
  response => {
    const res = response.data
    if (res.code && res.code !== 200) {
      ElMessage.error(res.message || '请求失败')
      return Promise.reject(new Error(res.message || '请求失败'))
    }
    return res
  },
  error => {
    if (error.response) {
      const { status, data } = error.response
      if (status === 401) {
        ElMessage.error('未登录或登录已过期')
        localStorage.removeItem('token')
        window.location.href = '/login'
      } else if (status === 403) {
        ElMessage.error(data?.message || '权限不足')
      } else if (status === 404) {
        ElMessage.error(data?.message || '资源不存在')
      } else {
        ElMessage.error(data?.message || `请求错误 (${status})`)
      }
    } else {
      ElMessage.error('网络异常')
    }
    return Promise.reject(error)
  }
)

export default request
