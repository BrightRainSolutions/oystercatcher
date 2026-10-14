<script setup>
const model = defineModel({ type: Number, default: null })
const props = defineProps({
  size: { type: Number, default: 48 },
  readonly: { type: Boolean, default: false },
  color: { type: String, default: 'var(--accent)' },
})

function pick(n) {
  if (props.readonly) return
  model.value = model.value === n ? null : n
}
</script>

<template>
  <div class="shells" role="radiogroup" aria-label="Overall rating" :class="{ readonly }">
    <button
      v-for="n in 5"
      :key="n"
      type="button"
      role="radio"
      :aria-checked="model === n"
      :aria-label="`${n} of 5`"
      :disabled="readonly"
      class="shell"
      :class="{ on: model != null && n <= model }"
      :style="{ width: `${size}px`, height: `${size}px`, '--c': color }"
      @click="pick(n)"
    >
      <svg viewBox="0 0 48 48" aria-hidden="true">
        <path
          class="body"
          d="M24 5c6 0 9 4 11 8 6 1 9 5 9 10 0 10-9 20-20 20S4 33 4 23c0-5 3-9 9-10 2-4 5-8 11-8z"
        />
        <path class="ridge" d="M24 9v30M16 13c-2 8-2 17 2 25M32 13c2 8 2 17-2 25M10 20c0 7 2 13 5 17M38 20c0 7-2 13-5 17" />
      </svg>
    </button>
  </div>
</template>

<style scoped>
.shells { display: flex; gap: 4px; }
.shell {
  border: 0;
  padding: 2px;
  background: none;
  cursor: pointer;
  transition: transform 0.12s cubic-bezier(0.3, 1.6, 0.6, 1);
}
.readonly .shell { cursor: default; }
.shell:not(:disabled):active { transform: scale(0.85); }
.shell.on { transform: scale(1.06); }
svg { width: 100%; height: 100%; display: block; }
.body {
  fill: var(--surface-2);
  stroke: color-mix(in srgb, var(--text) 25%, transparent);
  stroke-width: 2;
  transition: fill 0.15s ease;
}
.ridge {
  fill: none;
  stroke: color-mix(in srgb, var(--text) 18%, transparent);
  stroke-width: 1.6;
  stroke-linecap: round;
}
.on .body { fill: var(--c); stroke: color-mix(in srgb, var(--c) 70%, black); }
.on .ridge { stroke: rgba(255, 255, 255, 0.55); }
</style>
