<script setup>
const model = defineModel({ type: Boolean, default: false })
defineProps({ label: { type: String, default: '' } })
</script>

<template>
  <label class="toggle">
    <span v-if="label" class="lbl">{{ label }}</span>
    <button type="button" role="switch" :aria-checked="!!model" class="sw" :class="{ on: model }" @click="model = !model">
      <span class="knob" />
    </button>
  </label>
</template>

<style scoped>
.toggle { display: inline-flex; align-items: center; gap: 10px; cursor: pointer; }
.lbl { font-weight: 700; }
.sw {
  position: relative;
  width: 60px;
  height: 36px;
  border: 0;
  border-radius: 999px;
  background: var(--surface-2);
  box-shadow: inset 0 0 0 2px var(--line);
  cursor: pointer;
  transition: background 0.15s ease;
}
.sw.on { background: var(--kelp); box-shadow: none; }
.knob {
  position: absolute;
  top: 4px;
  left: 4px;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: #fff;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.25);
  transition: transform 0.18s cubic-bezier(0.3, 1.4, 0.6, 1);
}
.on .knob { transform: translateX(24px); }
</style>
