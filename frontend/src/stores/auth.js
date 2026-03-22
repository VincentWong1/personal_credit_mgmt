import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { authApi } from '../api/auth'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('access_token') || '')
  const refreshToken = ref(localStorage.getItem('refresh_token') || '')
  const user = ref(JSON.parse(localStorage.getItem('user') || 'null'))

  const isLoggedIn = computed(() => !!token.value)
  const isAdmin = computed(() => user.value?.role === 'admin')
  const isOperator = computed(() => ['admin', 'operator'].includes(user.value?.role))

  async function login(username, password) {
    const res = await authApi.login(username, password)
    token.value = res.access_token
    refreshToken.value = res.refresh_token
    localStorage.setItem('access_token', res.access_token)
    localStorage.setItem('refresh_token', res.refresh_token)
    await fetchUser()
  }

  async function fetchUser() {
    const res = await authApi.getMe()
    user.value = res
    localStorage.setItem('user', JSON.stringify(res))
  }

  async function refresh() {
    try {
      const res = await authApi.refresh(refreshToken.value)
      token.value = res.access_token
      refreshToken.value = res.refresh_token
      localStorage.setItem('access_token', res.access_token)
      localStorage.setItem('refresh_token', res.refresh_token)
      return true
    } catch {
      logout()
      return false
    }
  }

  function logout() {
    token.value = ''
    refreshToken.value = ''
    user.value = null
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('user')
  }

  return { token, refreshToken, user, isLoggedIn, isAdmin, isOperator, login, fetchUser, refresh, logout }
})
