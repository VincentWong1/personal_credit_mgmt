import request from './request'

export const commonApi = {
  getCompanies() {
    return request.get('/companies')
  },
  createCompany(name) {
    return request.post('/companies', { name })
  },
  getProjects(company_id) {
    const params = company_id ? { company_id } : {}
    return request.get('/projects', { params })
  },
  createProject(data) {
    return request.post('/projects', data)
  },
  getStats() {
    return request.get('/stats/overview')
  },
}
