import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/LoginView.vue'),
    meta: { requiresAuth: false },
  },
  {
    path: '/',
    component: () => import('../layouts/AppLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      { path: '', name: 'Dashboard', component: () => import('../views/DashboardView.vue') },
      { path: 'workers', name: 'Workers', component: () => import('../views/WorkerListView.vue') },
      { path: 'workers/new', name: 'WorkerNew', component: () => import('../views/WorkerFormView.vue'), meta: { requiresOperator: true } },
      { path: 'workers/:id', name: 'WorkerDetail', component: () => import('../views/WorkerDetailView.vue') },
      { path: 'workers/:id/edit', name: 'WorkerEdit', component: () => import('../views/WorkerFormView.vue'), meta: { requiresOperator: true } },
      { path: 'events', name: 'Events', component: () => import('../views/EventListView.vue') },
      { path: 'events/new', name: 'EventNewGlobal', component: () => import('../views/EventFormView.vue'), meta: { requiresOperator: true } },
      { path: 'workers/:id/events/new', name: 'EventNew', component: () => import('../views/EventFormView.vue'), meta: { requiresOperator: true } },
      { path: 'events/:id/edit', name: 'EventEdit', component: () => import('../views/EventFormView.vue'), meta: { requiresOperator: true } },
      { path: 'users', name: 'Users', component: () => import('../views/UserListView.vue'), meta: { requiresAdmin: true } },
      { path: 'profile', name: 'Profile', component: () => import('../views/ProfileView.vue') },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to, from, next) => {
  const auth = useAuthStore()

  if (to.meta.requiresAuth !== false && !auth.token) {
    return next('/login')
  }

  if (to.meta.requiresAdmin && auth.user?.role !== 'admin') {
    return next('/')
  }

  if (to.meta.requiresOperator && !['admin', 'operator'].includes(auth.user?.role)) {
    return next('/')
  }

  next()
})

export default router
