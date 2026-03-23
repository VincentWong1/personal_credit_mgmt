import request from './request'

export const authApi = {
  login(username, password) {
    return request.post('/auth/login', { username, password })
  },
  refresh(refresh_token) {
    return request.post('/auth/refresh', { refresh_token })
  },
  getMe() {
    return request.get('/auth/me')
  },
  changePassword(old_password, new_password) {
    return request.put('/auth/password', { old_password, new_password })
  },
}
