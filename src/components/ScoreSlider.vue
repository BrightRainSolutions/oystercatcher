<script setup>
// 1–5 slider that can also be "not rated" (null). Untouched sliders stay ghosted.
const model = defineModel({ type: Number, default: null })
defineProps({
  label: { type: String, required: true },
  low: { type: String, required: true },
  high: { type: String, required: true },
  color: { type: String, default: 'var(--sea-3)' },
})

function onInput(e) {
  model.value = Number(e.target.value)
}
</script>

<template>
  <div class="slider" :class="{ unset: model == null }" :style="{ '--c': color }">
    <div class="head">
      <span class="label">{{ label }}</span>
      <span class="val">{{ model ?? '–' }}</span>
      <button v-if="model != null" type="button" class="clear" aria-label="Clear" @click="model = null">×</button>
    </div>
    <input
      type="range"
      min="1"
      max="5"
      step="1"
      :value="model ?? 3"
      :aria-label="label"
      @input="onInput"
      @pointerdown="model == null && (model = 3)"
    />
    <div class="ends small muted">
      <span>{{ low }}</span>
      <span>{{ high }}</span>
    </div>
  </div>
</template>

<style scoped>
.slider { padding: 6px 0; }
.head { display: flex; align-items: baseline; gap: 8px; }
.label { font-weight: 700; }
.val { margin-left: auto; font-family: var(--display); font-weight: 800; font-size: 1.2rem; color: var(--c); }
.unset .val { color: var(--muted); }
.clear {
  border: 0;
  background: var(--surface-2);
  border-radius: 50%;
  width: 26px;
  height: 26px;
  line-height: 1;
  cursor: pointer;
}
.ends { display: flex; justify-content: space-between; margin-top: -2px; }

input[type='range'] {
  -webkit-appearance: none;
  appearance: none;
  width: 100%;
  height: 40px;
  background: transparent;
  margin: 0;
}
input[type='range']::-webkit-slider-runnable-track {
  height: 10px;
  border-radius: 999px;
  background: linear-gradient(90deg, color-mix(in srgb, var(--c) 25%, var(--surface-2)), var(--c));
}
input[type='range']::-moz-range-track {
  height: 10px;
  border-radius: 999px;
  background: linear-gradient(90deg, color-mix(in srgb, var(--c) 25%, var(--surface-2)), var(--c));
}
input[type='range']::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 32px;
  height: 32px;
  margin-top: -11px;
  border-radius: 50%;
  background: var(--surface);
  border: 4px solid var(--c);
  box-shadow: var(--shadow);
}
input[type='range']::-moz-range-thumb {
  width: 26px;
  height: 26px;
  border-radius: 50%;
  background: var(--surface);
  border: 4px solid var(--c);
}
.unset input[type='range'] { opacity: 0.35; }
</style>
