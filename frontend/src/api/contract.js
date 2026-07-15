import request from './request'

export function getContractList(params) {
  return request.get('/contract/list', { params })
}

export function getContractDetail(id) {
  return request.get(`/contract/${id}`)
}

export function createContract(data) {
  return request.post('/contract/create', data)
}

export function submitContract(id, comment) {
  return request.post(`/contract/${id}/submit`, null, { params: { comment } })
}

export function processContract(id, comment) {
  return request.post(`/contract/${id}/process`, null, { params: { comment } })
}

export function approveContract(id, comment) {
  return request.post(`/contract/${id}/approve`, null, { params: { comment } })
}

export function withdrawContract(id, comment) {
  return request.post(`/contract/${id}/withdraw`, null, { params: { comment } })
}

export function deleteContract(id, comment) {
  return request.delete(`/contract/${id}`, { params: { comment } })
}

export function getApprovalRecords(id) {
  return request.get(`/contract/${id}/records`)
}

export function getDeptList() {
  return request.get('/dept/list')
}

export function getAuditLogList(params) {
  return request.get('/audit/list', { params })
}

export function getFieldConfigList() {
  return request.get('/field-config/list')
}

export function addFieldConfig(data) {
  return request.post('/field-config', data)
}

export function updateFieldConfig(data) {
  return request.put('/field-config', data)
}

export function deleteFieldConfig(id) {
  return request.delete(`/field-config/${id}`)
}
