<script setup>
// 1–5 slider that can also be "not rated" (null). Unrated shows a hollow knob
// parked in the middle, a grey track and a "Not rated" tag, so it can't be
// mistaken for a 3. The first deliberate touch makes it real: a drag or a tap
// on the track sets that value, and a tap on the parked knob means 3.
// Vertical swipes scroll the page (touch-action: pan-y) and never set a score.
import { computed, ref } from 'vue'

const model = defineModel({ type: Number, default: null })
const props = defineProps({
  label: { type: String, required: true },
  low: { type: String, required: true },
  high: { type: String, required: true },
  color: { type: String, default: 'var(--sea-3)' },
})

// Live word for the current value, built from the two end labels.
const word = computed(() => {
  switch (model.value) {
    case 1: return props.low
    case 2: return `leaning ${props.low}`
    case 3: return 'right in the middle'
    case 4: return `leaning ${props.high}`
    case 5: return props.high
    default: return ''
  }
})

const onInput = (e) => (model.value = Number(e.target.value))

// A tap on the parked knob doesn't fire `input` (the value doesn't change),
// so treat a short, still press as "yes, 3".
let down = null
function onPointerDown(e) {
  down = model.value == null ? { x: e.clientX, y: e.clientY } : null
}
function onPointerUp(e) {
  if (down && model.value == null && Math.hypot(e.clientX - down.x, e.clientY - down.y) < 8) model.value = 3
  down = null
}
</script>

<template>
  <div class="slider" :class="{ unset: model == null }" :style="{ '--c': color }">
    <div class="head">
      <span class="label">{{ label }}</span>
      <span v-if="model == null" class="tag">Not rated</span>
      <template v-else>
        <span class="word">{{ word }}</span>
        <span class="val">{{ model }}</span>
        <button type="button" class="clear" :aria-label="`Clear ${label}`" @click="model = null">×</button>
      </template>
    </div>
    <input
      type="range"
      min="1"
      max="5"
      step="1"
      :value="model ?? 3"
      :aria-label="label"
      :aria-valuetext="model == null ? 'Not rated' : `${model}, ${word}`"
      @input="onInput"
      @pointerdown="onPointerDown"
      @pointerup="onPointerUp"
      @pointercancel="down = null"
    />
    <div class="ticks" aria-hidden="true">
      <span v-for="n in 5" :key="n" :class="{ on: model === n }" />
    </div>
    <div class="ends small muted">
      <span>{{ low }}</span>
      <span>{{ high }}</span>
    </div>
  </div>
</template>

<style scoped>
.slider { --thumb: 30px; padding: 8px 0 6px; }
.head { display: flex; align-items: center; gap: 8px; min-height: 28px; }
.label { flex: none; font-weight: 700; white-space: nowrap; }
.tag {
  margin-left: auto;
  padding: 2px 10px;
  border: 1.5px dashed var(--line);
  border-radius: 999px;
  color: var(--muted);
  font-size: 0.78rem;
  font-weight: 700;
}
.word {
  margin-left: auto;
  color: var(--muted);
  font-size: 0.85rem;
  font-style: italic;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  min-width: 0;
}
.val { font-family: var(--display); font-weight: 800; font-size: 1.2rem; color: var(--c); }
.clear {
  flex: none;
  width: 28px;
  height: 28px;
  border: 0;
  border-radius: 50%;
  background: var(--surface-2);
  line-height: 1;
  cursor: pointer;
}

input[type='range'] {
  -webkit-appearance: none;
  appearance: none;
  display: block;
  width: 100%;
  height: 40px;
  margin: 0;
  background: transparent;
  touch-action: pan-y;
}
input[type='range']::-webkit-slider-runnable-track {
  height: 8px;
  border-radius: 999px;
  background: var(--c);
}
input[type='range']::-moz-range-track {
  height: 8px;
  border-radius: 999px;
  background: var(--c);
}
input[type='range']::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: var(--thumb);
  height: var(--thumb);
  margin-top: calc((8px - var(--thumb)) / 2);
  border-radius: 50%;
  background: var(--c);
  border: 4px solid var(--surface);
  box-shadow: 0 0 0 1.5px var(--c);
}
input[type='range']::-moz-range-thumb {
  width: calc(var(--thumb) - 8px);
  height: calc(var(--thumb) - 8px);
  border-radius: 50%;
  background: var(--c);
  border: 4px solid var(--surface);
  box-shadow: 0 0 0 1.5px var(--c);
}

/* Unrated: grey track, hollow ring knob. */
.unset input[type='range']::-webkit-slider-runnable-track { background: var(--surface-2); }
.unset input[type='range']::-moz-range-track { background: var(--surface-2); }
.unset input[type='range']::-webkit-slider-thumb {
  background: var(--surface);
  border: 3px dashed var(--muted);
  box-shadow: none;
}
.unset input[type='range']::-moz-range-thumb {
  background: var(--surface);
  border: 3px dashed var(--muted);
  box-shadow: none;
}

/* Tick marks line up with the thumb centers, which sit half a thumb in from each end. */
.ticks {
  display: flex;
  justify-content: space-between;
  padding: 0 calc(var(--thumb) / 2 - 1px);
  margin-top: -6px;
}
.ticks span {
  width: 2px;
  height: 8px;
  border-radius: 1px;
  background: var(--line);
}
.ticks span.on { background: var(--c); height: 10px; }
.ends { display: flex; justify-content: space-between; margin-top: 2px; }
</style>
