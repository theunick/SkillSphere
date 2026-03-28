<template>
  <div>
    <div class="page-header">
      <h2>DASHBOARD</h2>
      <p>Real-time seismic event monitoring</p>
    </div>

    <StatsPanel :events="allEvents" />

    <div class="card">
      <div class="card-header">
        <h3>Live Event Feed</h3>
        <span class="feed-count">{{ liveEvents.length }} events captured</span>
      </div>
      <div v-if="liveEvents.length === 0" class="empty-state">
        <div class="loading-spinner" v-if="connecting"></div>
        <p v-if="connecting">Connecting to event stream...</p>
        <p v-else>No events received yet. Waiting for seismic data...</p>
      </div>
      <div class="event-feed" v-else>
        <EventCard v-for="event in liveEvents" :key="event.id || event._uid" :event="event" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import EventCard from '../components/EventCard.vue'
import StatsPanel from '../components/StatsPanel.vue'

const emit = defineEmits(['sse-status'])

const liveEvents = ref([])
const allEvents = ref([])
const connecting = ref(true)
let eventSource = null
let uidCounter = 0

function connectSSE() {
  connecting.value = true
  eventSource = new EventSource('/api/events/stream')

  eventSource.onopen = () => {
    connecting.value = false
    emit('sse-status', true)
  }

  eventSource.onmessage = (msg) => {
    try {
      const event = JSON.parse(msg.data)
      event._uid = ++uidCounter
      liveEvents.value.unshift(event)
      allEvents.value.unshift(event)
      if (liveEvents.value.length > 200) {
        liveEvents.value.pop()
      }
    } catch {
      // skip malformed messages
    }
  }

  eventSource.onerror = () => {
    connecting.value = false
    emit('sse-status', false)
    eventSource.close()
    setTimeout(connectSSE, 5000)
  }
}

async function fetchInitialEvents() {
  try {
    const res = await fetch('/api/events?limit=50&offset=0')
    if (res.ok) {
      const data = await res.json()
      const events = Array.isArray(data) ? data : data.events || []
      allEvents.value = events
    }
  } catch {
    // backend may not be available yet
  }
}

onMounted(() => {
  fetchInitialEvents()
  connectSSE()
})

onUnmounted(() => {
  if (eventSource) {
    eventSource.close()
    emit('sse-status', false)
  }
})
</script>

<style scoped>
.feed-count {
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--text-muted);
}
</style>
