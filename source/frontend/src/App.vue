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
        <router-link to="/" class="nav-item" exact-active-class="active">
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
      <router-view :sse-connected="sseConnected" @sse-status="sseConnected = $event" />
    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const sseConnected = ref(false)
</script>
