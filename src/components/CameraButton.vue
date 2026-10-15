<script setup>
// Picks a photo and hands it to `save`. No `capture` attribute on purpose:
// phones then offer camera *or* library, so a photo taken earlier can be used.
import { ref } from 'vue'

const props = defineProps({
  label: { type: String, default: '' },
  small: { type: Boolean, default: false },
  // async (file) => void; errors are shown under the button
  save: { type: Function, required: true },
})
const input = ref(null)
const busy = ref(false)
const error = ref('')

async function onChange(e) {
  const file = e.target.files?.[0]
  e.target.value = ''
  if (!file) return
  busy.value = true
  error.value = ''
  try {
    await props.save(file)
  } catch (err) {
    console.warn('[photo]', err)
    // Keep the raw reason visible: family members won't have a dev console.
    const reason = [err?.name, err?.message].filter(Boolean).join(': ') || String(err)
    error.value = err?.userMessage || `Couldn't save that photo. Try again? (${reason})`
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div class="cam-wrap" :class="{ small }">
    <button type="button" class="cam" :class="{ small }" :disabled="busy" @click="input.click()">
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path
          d="M4 8.5A2.5 2.5 0 0 1 6.5 6H8l1.3-1.8A1.5 1.5 0 0 1 10.5 3.6h3a1.5 1.5 0 0 1 1.2.6L16 6h1.5A2.5 2.5 0 0 1 20 8.5v8a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 4 16.5z"
          fill="none"
          stroke="currentColor"
          stroke-width="1.8"
        />
        <circle cx="12" cy="12.4" r="3.6" fill="none" stroke="currentColor" stroke-width="1.8" />
      </svg>
      <span v-if="label">{{ busy ? 'Developing…' : label }}</span>
      <input ref="input" type="file" accept="image/*" hidden @change="onChange" />
    </button>
    <p v-if="error" class="cam-error small" role="alert">{{ error }}</p>
  </div>
</template>

<style scoped>
.cam-wrap.small { display: inline-block; }
.cam-error { margin: 6px 0 0; color: var(--coral); font-weight: 600; }
.cam {
  display: inline-flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  width: 100%;
  min-height: 200px;
  border: 3px dashed color-mix(in srgb, var(--cream) 50%, transparent);
  border-radius: var(--radius);
  background: linear-gradient(160deg, var(--sea-2), var(--sea));
  color: var(--cream);
  font-family: var(--display);
  font-size: 1.3rem;
  font-weight: 800;
  cursor: pointer;
}
.cam svg { width: 64px; height: 64px; }
.cam.small {
  flex-direction: row;
  width: auto;
  min-height: 44px;
  padding: 0 14px;
  border: 0;
  border-radius: 999px;
  background: var(--surface-2);
  color: var(--text);
  font-family: var(--body);
  font-size: 0.9rem;
  font-weight: 700;
}
.cam.small svg { width: 22px; height: 22px; }
</style>
