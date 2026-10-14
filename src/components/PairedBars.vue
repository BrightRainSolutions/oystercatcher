<script setup>
// One row per attribute, one bar per person, in that person's color.
// rows: [{ label, low, high, values: [{ color, value, name }] }]
defineProps({
  rows: { type: Array, required: true },
  showEnds: { type: Boolean, default: false },
})
const pct = (v) => (v == null ? 0 : (Number(v) / 5) * 100)
const fmt = (v) => (v == null ? '–' : Number(v) % 1 ? Number(v).toFixed(1) : String(v))
</script>

<template>
  <div class="bars">
    <div v-for="row in rows" :key="row.label" class="attr">
      <div class="name">
        {{ row.label }}
        <span v-if="showEnds" class="small muted"> · {{ row.low }} → {{ row.high }}</span>
      </div>
      <div v-for="(v, i) in row.values" :key="i" class="line">
        <div class="track">
          <div class="fill" :style="{ width: `${pct(v.value)}%`, background: v.color }" />
        </div>
        <span class="num" :style="{ color: v.value == null ? 'var(--muted)' : v.color }">{{ fmt(v.value) }}</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.attr + .attr { margin-top: 10px; }
.name { font-weight: 700; font-size: 0.9rem; margin-bottom: 3px; }
.line { display: flex; align-items: center; gap: 8px; }
.line + .line { margin-top: 3px; }
.track {
  flex: 1;
  height: 9px;
  border-radius: 999px;
  background: var(--surface-2);
  overflow: hidden;
}
.fill {
  height: 100%;
  border-radius: 999px;
  transition: width 0.4s cubic-bezier(0.2, 0.8, 0.2, 1);
}
.num { width: 28px; text-align: right; font-weight: 800; font-size: 0.85rem; }
</style>
