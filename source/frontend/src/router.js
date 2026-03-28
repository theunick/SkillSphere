import { createRouter, createWebHistory } from 'vue-router'
import Dashboard from './views/Dashboard.vue'
import Events from './views/Events.vue'
import Sensors from './views/Sensors.vue'

const routes = [
  { path: '/', name: 'Dashboard', component: Dashboard },
  { path: '/events', name: 'Events', component: Events },
  { path: '/sensors', name: 'Sensors', component: Sensors },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

export default router
