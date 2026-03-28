<template>
  <div class="app-layout">
    <aside class="sidebar">
      <div class="sidebar-header">
        <div class="logo">
          <span class="logo-icon">&#9672;</span>
          <div>
            <h1>SEISMIC</h1>
            <span class="logo-sub">ANALYSIS PLATFORM</span>
          </div>
        </div>
      </div>
      <nav class="sidebar-nav">
        <router-link to="/" class="nav-item" active-class="active" :exact="true">
          <span class="nav-icon">&#9632;</span>
          <span>Dashboard</span>
        </router-link>
        <router-link to="/events" class="nav-item" active-class="active">
          <span class="nav-icon">&#9776;</span>
          <span>Event History</span>
        </router-link>
        <router-link to="/sensors" class="nav-item" active-class="active">
          <span class="nav-icon">&#9881;</span>
          <span>Sensors</span>
        </router-link>
      </nav>
      <div class="sidebar-footer">
        <div class="connection-status" :class="{ connected: sseConnected }">
          <span class="status-dot"></span>
          {{ sseConnected ? 'STREAM ACTIVE' : 'DISCONNECTED' }}
        </div>
      </div>
    </aside>
    <main class="main-content">
      <router-view :live-events="liveEvents" :all-events="allEvents" :sse-connected="sseConnected" />
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const sseConnected = ref(false)
const liveEvents = ref([])
const allEvents = ref([])
let eventSource = null
let reconnectTimer = null
let uidCounter = 0

function connectSSE() {
  if (eventSource) {
    eventSource.close()
    eventSource = null
  }

  eventSource = new EventSource('/api/events/stream')

  eventSource.onopen = () => {
    sseConnected.value = true
  }

  eventSource.addEventListener('new_event', (msg) => {
    try {
      const event = JSON.parse(msg.data)
      event._uid = ++uidCounter
      liveEvents.value.unshift(event)
      allEvents.value.unshift(event)
      if (liveEvents.value.length > 200) {
        liveEvents.value.pop()
      }
      if (allEvents.value.length > 500) {
        allEvents.value.pop()
      }
    } catch {
      // skip malformed
    }
  })

  eventSource.onerror = () => {
    sseConnected.value = false
    if (eventSource) {
      eventSource.close()
      eventSource = null
    }
    reconnectTimer = setTimeout(connectSSE, 5000)
  }
}

async function fetchInitialEvents() {
  try {
    const res = await fetch('/api/events?limit=50&offset=0')
    if (res.ok) {
      const data = await res.json()
      allEvents.value = Array.isArray(data) ? data : []
    }
  } catch {
    // backend may not be ready
  }
}

onMounted(() => {
  fetchInitialEvents()
  connectSSE()
})

onUnmounted(() => {
  if (reconnectTimer) clearTimeout(reconnectTimer)
  if (eventSource) {
    eventSource.close()
    eventSource = null
  }
})
</script>
