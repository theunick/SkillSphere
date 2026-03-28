<template>
  <div>
    <div class="page-header">
      <h2>EVENT HISTORY</h2>
      <p>Browse and filter historical seismic events</p>
    </div>

    <div class="card" style="margin-bottom: 16px;">
      <div class="filters-bar">
        <div class="filter-group">
          <label>Sensor</label>
          <input
            v-model="filterSensor"
            type="text"
            class="form-input"
            placeholder="e.g. sensor-01"
            @input="resetAndFetch"
          />
        </div>
        <div class="filter-group">
          <label>Type</label>
          <select v-model="filterType" class="form-select" @change="resetAndFetch">
            <option value="">All Types</option>
            <option value="earthquake">Earthquake</option>
            <option value="conventional_explosion">Conv. Explosion</option>
            <option value="nuclear_like">Nuclear-Like</option>
          </select>
        </div>
        <button class="btn" @click="resetAndFetch">Apply</button>
      </div>
    </div>

    <div class="card">
      <div class="card-header">
        <h3>Events</h3>
        <span class="result-count">{{ events.length }} loaded</span>
      </div>

      <div v-if="loading" class="empty-state">
        <div class="loading-spinner"></div>
        <p style="margin-top: 12px;">Loading events...</p>
      </div>

      <div v-else-if="events.length === 0" class="empty-state">
        <p>No events found matching your filters.</p>
      </div>

      <div v-else class="table-wrapper">
        <table class="data-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Timestamp</th>
              <th>Sensor</th>
              <th>Type</th>
              <th>Frequency (Hz)</th>
              <th>Amplitude</th>
              <th>Detected By</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="ev in events" :key="ev.id">
              <td>#{{ ev.id }}</td>
              <td>{{ formatTime(ev.timestamp) }}</td>
              <td>{{ ev.sensor_id }}</td>
              <td>
                <span class="badge" :class="badgeClass(ev.event_type)">
                  {{ displayType(ev.event_type) }}
                </span>
              </td>
              <td>{{ ev.dominant_frequency?.toFixed(2) }}</td>
              <td>{{ ev.amplitude?.toFixed(2) }}</td>
              <td class="cell-dim">{{ ev.detected_by || '--' }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="pagination">
        <button class="btn" :disabled="offset === 0" @click="prevPage">Previous</button>
        <span class="pagination-info">
          {{ offset + 1 }} - {{ offset + events.length }}
        </span>
        <button class="btn" :disabled="events.length < limit" @click="nextPage">Next</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const events = ref([])
const loading = ref(false)
const filterSensor = ref('')
const filterType = ref('')
const limit = 50
const offset = ref(0)

function badgeClass(type) {
  switch (type) {
    case 'earthquake': return 'badge-earthquake'
    case 'conventional_explosion': return 'badge-conventional'
    case 'nuclear_like': return 'badge-nuclear'
    default: return ''
  }
}

function displayType(type) {
  switch (type) {
    case 'earthquake': return 'EARTHQUAKE'
    case 'conventional_explosion': return 'CONV. EXPLOSION'
    case 'nuclear_like': return 'NUCLEAR-LIKE'
    default: return type?.toUpperCase() || 'UNKNOWN'
  }
}

function formatTime(ts) {
  if (!ts) return '--'
  const d = new Date(ts)
  return d.toLocaleString('en-GB', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  })
}

async function fetchEvents() {
  loading.value = true
  try {
    const params = new URLSearchParams({
      limit: limit.toString(),
      offset: offset.value.toString(),
    })
    if (filterSensor.value) params.set('sensor_id', filterSensor.value)
    if (filterType.value) params.set('event_type', filterType.value)

    const res = await fetch(`/api/events?${params}`)
    if (res.ok) {
      const data = await res.json()
      events.value = Array.isArray(data) ? data : data.events || []
    }
  } catch {
    events.value = []
  } finally {
    loading.value = false
  }
}

function resetAndFetch() {
  offset.value = 0
  fetchEvents()
}

function prevPage() {
  offset.value = Math.max(0, offset.value - limit)
  fetchEvents()
}

function nextPage() {
  offset.value += limit
  fetchEvents()
}

onMounted(fetchEvents)
</script>

<style scoped>
.table-wrapper {
  overflow-x: auto;
}

.result-count {
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--text-muted);
}

.cell-dim {
  color: var(--text-secondary);
  font-size: 11px;
}
</style>
