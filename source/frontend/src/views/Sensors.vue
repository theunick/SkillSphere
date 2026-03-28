<template>
  <div>
    <div class="page-header">
      <h2>SENSORS</h2>
      <p>Active sensor nodes in the monitoring network</p>
    </div>

    <div v-if="loading" class="card">
      <div class="empty-state">
        <div class="loading-spinner"></div>
        <p style="margin-top: 12px;">Loading sensor data...</p>
      </div>
    </div>

    <div v-else-if="sensors.length === 0" class="card">
      <div class="empty-state">
        <p>No sensors registered in the system.</p>
      </div>
    </div>

    <div v-else class="grid-3 sensor-grid">
      <div class="card sensor-card" v-for="sensor in sensors" :key="sensor.id || sensor.sensor_id">
        <div class="sensor-header">
          <span class="sensor-id">{{ sensor.sensor_id || sensor.id }}</span>
          <span class="sensor-status" :class="sensor.active !== false ? 'online' : 'offline'">
            {{ sensor.active !== false ? 'ONLINE' : 'OFFLINE' }}
          </span>
        </div>
        <div class="sensor-details">
          <div class="sensor-field" v-if="sensor.location">
            <span class="sensor-label">LOCATION</span>
            <span class="sensor-value">{{ sensor.location }}</span>
          </div>
          <div class="sensor-field" v-if="sensor.latitude != null">
            <span class="sensor-label">COORDINATES</span>
            <span class="sensor-value">
              {{ sensor.latitude?.toFixed(4) }}, {{ sensor.longitude?.toFixed(4) }}
            </span>
          </div>
          <div class="sensor-field" v-if="sensor.type">
            <span class="sensor-label">TYPE</span>
            <span class="sensor-value">{{ sensor.type }}</span>
          </div>
          <div class="sensor-field" v-if="sensor.last_seen">
            <span class="sensor-label">LAST SEEN</span>
            <span class="sensor-value">{{ formatTime(sensor.last_seen) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const sensors = ref([])
const loading = ref(false)

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

async function fetchSensors() {
  loading.value = true
  try {
    const res = await fetch('/api/sensors')
    if (res.ok) {
      const data = await res.json()
      sensors.value = Array.isArray(data) ? data : data.sensors || []
    }
  } catch {
    sensors.value = []
  } finally {
    loading.value = false
  }
}

onMounted(fetchSensors)
</script>

<style scoped>
.sensor-grid {
  margin-top: 8px;
}

.sensor-card {
  padding: 16px 20px;
}

.sensor-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
  padding-bottom: 10px;
  border-bottom: 1px solid var(--border-color);
}

.sensor-id {
  font-family: var(--font-mono);
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.sensor-status {
  font-family: var(--font-mono);
  font-size: 10px;
  letter-spacing: 1px;
  padding: 3px 8px;
  border-radius: 3px;
}

.sensor-status.online {
  background: rgba(0, 255, 136, 0.12);
  color: var(--accent-green);
  border: 1px solid rgba(0, 255, 136, 0.3);
}

.sensor-status.offline {
  background: rgba(255, 51, 51, 0.12);
  color: var(--accent-red);
  border: 1px solid rgba(255, 51, 51, 0.3);
}

.sensor-details {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.sensor-field {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.sensor-label {
  font-family: var(--font-mono);
  font-size: 10px;
  letter-spacing: 1px;
  color: var(--text-muted);
}

.sensor-value {
  font-family: var(--font-mono);
  font-size: 12px;
  color: var(--text-secondary);
}
</style>
