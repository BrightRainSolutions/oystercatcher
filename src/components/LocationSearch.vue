<script setup>
// Place search for pinning: debounced Nominatim (the helper also enforces
// 1 request/sec), results as a dropdown, OSM attribution shown with results.
import { ref, watch } from 'vue'
import { nominatimSearch } from '../lib/geo'

const props = defineProps({
  // Pre-filled query, e.g. the oyster's growing area. Searches right away.
  initial: { type: String, default: '' },
  placeholder: { type: String, default: 'Search a bay, inlet, town…' },
})
const emit = defineEmits(['pick']) // { lat, lng, label }

const query = ref(props.initial)
const results = ref([])
const searching = ref(false)
const error = ref('')

let debounce = null
function search(qq) {
  clearTimeout(debounce)
  error.value = ''
  if (qq.trim().length < 3) {
    results.value = []
    return
  }
  debounce = setTimeout(async () => {
    searching.value = true
    try {
      results.value = await nominatimSearch(qq.trim())
      if (!results.value.length) error.value = 'Nothing found. Try a nearby town, or tap the map.'
    } catch {
      error.value = 'Search is napping. Tap the map instead.'
    } finally {
      searching.value = false
    }
  }, 700)
}
watch(query, search)
if (props.initial) search(props.initial)

function pick(r) {
  emit('pick', r)
  results.value = []
}
</script>

<template>
  <div class="locsearch">
    <input v-model="query" class="input" type="search" :placeholder="placeholder" autocomplete="off" />
    <div v-if="results.length || searching || error" class="results card">
      <p v-if="searching" class="small muted msg">Looking…</p>
      <p v-if="error" class="small muted msg">{{ error }}</p>
      <button v-for="r in results" :key="`${r.lat},${r.lng}`" type="button" class="res" @click="pick(r)">
        {{ r.label }}
      </button>
      <p class="attr small muted">
        Search by <a href="https://nominatim.openstreetmap.org/" target="_blank" rel="noopener">Nominatim</a>
        · © <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">OpenStreetMap</a> contributors
      </p>
    </div>
  </div>
</template>

<style scoped>
.locsearch { position: relative; z-index: 10; }
.results {
  position: absolute;
  left: 0;
  right: 0;
  top: calc(100% + 6px);
  max-height: 50vh;
  overflow-y: auto;
  padding: 6px;
}
.msg { margin: 0; padding: 8px 12px; }
.res {
  display: block;
  width: 100%;
  min-height: 44px;
  text-align: left;
  border: 0;
  background: none;
  padding: 10px 12px;
  border-radius: 10px;
  cursor: pointer;
}
.res:hover { background: var(--surface-2); }
.attr { padding: 6px 12px 2px; margin: 0; }
</style>
