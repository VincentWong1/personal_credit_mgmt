import request from './request'

export const usersApi = {
  list(params) {
    return request.get('/users', { params })
  },
  get(id) {
    return request.get(`/users/${id}`)
  },
  create(data) {
    return request.post('/users', data)
  },
  update(id, data) {
    return request.put(`/users/${id}`, data)
  },
  delete(id) {
    return request.delete(`/users/${id}`)
  },
}
