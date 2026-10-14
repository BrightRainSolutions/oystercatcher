<script setup>
import { useRouter } from 'vue-router'
import PendingPill from './PendingPill.vue'

const props = defineProps({
  title: { type: String, default: '' },
  back: { type: [Boolean, String, Object], default: false },
})
const router = useRouter()

function goBack() {
  if (typeof props.back === 'string' || typeof props.back === 'object') router.push(props.back)
  else if (window.history.state?.back) router.back()
  else router.push('/')
}
</script>

<template>
  <header class="topbar">
    <button v-if="back" class="btn icon back" aria-label="Back" @click="goBack">
      <svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true">
        <path d="M15 5l-7 7 7 7" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" />
      </svg>
    </button>
    <h2 class="title">{{ title }}</h2>
    <PendingPill />
    <slot />
  </header>
</template>

<style scoped>
.topbar {
  position: sticky;
  top: 0;
  z-index: 20;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: calc(8px + var(--safe-top)) 16px 8px;
  background: color-mix(in srgb, var(--bg) 88%, transparent);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}
.title {
  flex: 1;
  min-width: 0;
  margin: 0;
  font-size: 1.3rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.back {
  background: var(--surface);
  box-shadow: var(--shadow);
  flex: none;
}
</style>
