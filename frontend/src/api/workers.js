import request from './request'

export const workersApi = {
  list(params) {
    return request.get('/workers', { params })
  },
  get(id) {
    return request.get(`/workers/${id}`)
  },
  create(data) {
    return request.post('/workers', data)
  },
  update(id, data) {
    return request.put(`/workers/${id}`, data)
  },
  delete(id) {
    return request.delete(`/workers/${id}`)
  },
}
