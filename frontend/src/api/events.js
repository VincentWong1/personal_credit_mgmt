import request from './request'

export const eventsApi = {
  list(params) {
    return request.get('/events', { params })
  },
  get(eventId) {
    return request.get(`/events/${eventId}`)
  },
  listByWorker(workerId, params) {
    return request.get(`/workers/${workerId}/events`, { params })
  },
  create(workerId, data) {
    return request.post(`/workers/${workerId}/events`, data)
  },
  update(eventId, data) {
    return request.put(`/events/${eventId}`, data)
  },
  delete(eventId) {
    return request.delete(`/events/${eventId}`)
  },
  getCategories() {
    return request.get('/risk-categories')
  },
  createCategory(name) {
    return request.post('/risk-categories', { name })
  },
}
