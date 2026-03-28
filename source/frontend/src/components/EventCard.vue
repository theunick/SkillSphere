<template>
  <div class="event-card" :class="`event-card--${event.event_type}`">
    <div class="event-card__header">
      <span class="badge" :class="badgeClass">{{ displayType }}</span>
      <span class="event-card__time">{{ formattedTime }}</span>
    </div>
    <div class="event-card__body">
      <div class="event-card__field">
        <span class="event-card__label">SENSOR</span>
        <span class="event-card__value">{{ event.sensor_id }}</span>
      </div>
      <div class="event-card__field">
        <span class="event-card__label">FREQ</span>
        <span class="event-card__value">{{ event.dominant_frequency?.toFixed(2) }} Hz</span>
      </div>
      <div class="event-card__field">
        <span class="event-card__label">AMP</span>
        <span class="event-card__value">{{ event.amplitude?.toFixed(2) }}</span>
      </div>
      <div class="event-card__field">
        <span class="event-card__label">NODE</span>
        <span class="event-card__value event-card__value--dim">{{ event.detected_by || '--' }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  event: { type: Object, required: true },
})

const badgeClass = computed(() => {
  switch (props.event.event_type) {
    case 'earthquake': return 'badge-earthquake'
    case 'conventional_explosion': return 'badge-conventional'
    case 'nuclear_like': return 'badge-nuclear'
    default: return ''
  }
})

const displayType = computed(() => {
  switch (props.event.event_type) {
    case 'earthquake': return 'EARTHQUAKE'
    case 'conventional_explosion': return 'CONV. EXPLOSION'
    case 'nuclear_like': return 'NUCLEAR-LIKE'
    default: return props.event.event_type?.toUpperCase() || 'UNKNOWN'
  }
})

const formattedTime = computed(() => {
  if (!props.event.timestamp) return '--'
  const d = new Date(props.event.timestamp)
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
.event-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--radius);
  padding: 12px 16px;
  border-left: 3px solid var(--border-accent);
  transition: all var(--transition);
}

.event-card:hover {
  background: var(--bg-card-hover);
}

.event-card--earthquake {
  border-left-color: var(--accent-blue);
}

.event-card--conventional_explosion {
  border-left-color: var(--accent-amber);
}

.event-card--nuclear_like {
  border-left-color: var(--accent-red);
  background: rgba(255, 51, 51, 0.03);
}

.event-card__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}

.event-card__time {
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--text-muted);
}

.event-card__body {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
}

.event-card__field {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.event-card__label {
  font-family: var(--font-mono);
  font-size: 10px;
  letter-spacing: 1px;
  color: var(--text-muted);
}

.event-card__value {
  font-family: var(--font-mono);
  font-size: 13px;
  color: var(--text-primary);
}

.event-card__value--dim {
  color: var(--text-secondary);
  font-size: 11px;
}

@media (max-width: 768px) {
  .event-card__body {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
