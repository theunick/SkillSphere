<template>
  <div class="grid-4 stats-grid">
    <div class="card stat-card">
      <div class="stat-value">{{ stats.total }}</div>
      <div class="stat-label">Total Events</div>
    </div>
    <div class="card stat-card">
      <div class="stat-value stat-value--blue">{{ stats.earthquake }}</div>
      <div class="stat-label">Earthquakes</div>
    </div>
    <div class="card stat-card">
      <div class="stat-value stat-value--amber">{{ stats.conventional }}</div>
      <div class="stat-label">Conv. Explosions</div>
    </div>
    <div class="card stat-card stat-card--nuclear">
      <div class="stat-value stat-value--red">{{ stats.nuclear }}</div>
      <div class="stat-label">Nuclear-Like</div>
    </div>
  </div>
  <div class="card latest-event-card" v-if="latestTimestamp">
    <span class="latest-label">LATEST EVENT</span>
    <span class="latest-time">{{ latestTimestamp }}</span>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  events: { type: Array, default: () => [] },
})

const stats = computed(() => {
  const list = props.events
  return {
    total: list.length,
    earthquake: list.filter(e => e.event_type === 'earthquake').length,
    conventional: list.filter(e => e.event_type === 'conventional_explosion').length,
    nuclear: list.filter(e => e.event_type === 'nuclear_like').length,
  }
})

const latestTimestamp = computed(() => {
  if (!props.events.length) return null
  const sorted = [...props.events].sort(
    (a, b) => new Date(b.timestamp) - new Date(a.timestamp)
  )
  const d = new Date(sorted[0].timestamp)
  return d.toLocaleString('en-GB', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  })
})
</script>

<style scoped>
.stats-grid {
  margin-bottom: 16px;
}

.stat-card {
  text-align: center;
  padding: 20px 16px;
}

.stat-card--nuclear {
  border-color: rgba(255, 51, 51, 0.3);
}

.stat-value--blue {
  color: var(--accent-blue);
}

.stat-value--amber {
  color: var(--accent-amber);
}

.stat-value--red {
  color: var(--accent-red);
}

.latest-event-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 20px;
  margin-bottom: 16px;
}

.latest-label {
  font-family: var(--font-mono);
  font-size: 11px;
  letter-spacing: 1px;
  color: var(--text-muted);
}

.latest-time {
  font-family: var(--font-mono);
  font-size: 14px;
  color: var(--accent-green);
}
</style>
