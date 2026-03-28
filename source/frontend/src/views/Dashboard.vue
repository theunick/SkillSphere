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
        <div class="loading-spinner" v-if="sseConnected"></div>
        <p v-if="sseConnected">Connected. Waiting for seismic events...</p>
        <p v-else>Connecting to event stream...</p>
      </div>
      <div class="event-feed" v-else>
        <EventCard v-for="event in liveEvents" :key="event._uid" :event="event" />
      </div>
    </div>
  </div>
</template>

<script setup>
import EventCard from '../components/EventCard.vue'
import StatsPanel from '../components/StatsPanel.vue'

defineProps({
  liveEvents: { type: Array, default: () => [] },
  allEvents: { type: Array, default: () => [] },
  sseConnected: { type: Boolean, default: false },
})
</script>

<style scoped>
.feed-count {
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--text-muted);
}
</style>
