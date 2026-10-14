<script setup>
import { ref } from 'vue'
import { useQueue } from '../composables/useQueue'

const { pending, failed, flushing, lastError, flush, retryFailed, discardFailed } = useQueue()
const open = ref(false)
</script>

<template>
  <div v-if="pending || failed.length" class="wrap">
    <button class="pill" :class="{ bad: failed.length, busy: flushing }" @click="open = !open">
      <span class="dot" />
      <template v-if="pending">{{ pending }} pending</template>
      <template v-else>{{ failed.length }} stuck</template>
    </button>
    <div v-if="open" class="pop card small">
      <p v-if="pending">
        {{ pending }} change{{ pending === 1 ? '' : 's' }} waiting for signal. They'll sync on their own.
      </p>
      <p v-if="lastError" class="muted">Last hiccup: {{ lastError }}</p>
      <div class="row wrap">
        <button v-if="pending" class="btn" @click="flush">Try now</button>
        <template v-if="failed.length">
          <span>{{ failed.length }} couldn't save.</span>
          <button class="btn" @click="retryFailed">Retry</button>
          <button class="btn ghost" @click="discardFailed">Discard</button>
        </template>
      </div>
    </div>
  </div>
</template>

<style scoped>
.wrap { position: relative; }
.pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border: 0;
  border-radius: 999px;
  padding: 6px 12px;
  background: var(--surface-2);
  color: var(--muted);
  font-size: 0.8rem;
  font-weight: 700;
  white-space: nowrap;
  cursor: pointer;
}
.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--lemon);
}
.busy .dot { animation: pulse 1s ease-in-out infinite; }
.bad .dot { background: var(--coral); }
@keyframes pulse { 50% { opacity: 0.3; } }
.pop {
  position: absolute;
  right: 0;
  top: calc(100% + 8px);
  width: min(300px, 80vw);
  z-index: 50;
}
.pop p { margin: 0 0 10px; }
</style>
