<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import maplibregl from 'maplibre-gl'
import { getOysterBundle, loadOysters, updateOyster } from '../lib/data'
import { OFM_STYLE, nominatimSearch } from '../lib/geo'
import TopBar from '../components/TopBar.vue'

const route = useRoute()
const router = useRouter()

const oyster = ref(null)
const allOysters = ref([])
const point = ref(null) // { lat, lng }
const query = ref('')
const results = ref([])
const searching = ref(false)
const searchError = ref('')
const saving = ref(false)
const el = ref(null)
let map = null
let marker = null

const round = (n) => Math.round(n * 1e6) / 1e6

function setPoint(lat, lng, fly = false) {
  point.value = { lat: round(lat), lng: round(lng) }
  if (!marker) {
    marker = new maplibregl.Marker({ color: '#ff6b5a', draggable: true }).setLngLat([lng, lat]).addTo(map)
    marker.on('dragend', () => {
      const p = marker.getLngLat()
      point.value = { lat: round(p.lat), lng: round(p.lng) }
    })
  } else {
    marker.setLngLat([lng, lat])
  }
  if (fly) map.flyTo({ center: [lng, lat], zoom: Math.max(map.getZoom(), 9) })
}

onMounted(async () => {
  const [b, all] = await Promise.all([getOysterBundle(route.params.id), loadOysters()])
  oyster.value = b?.oyster
  allOysters.value = all
  if (oyster.value?.growing_area && !query.value) query.value = oyster.value.growing_area

  const o = oyster.value
  map = new maplibregl.Map({
    container: el.value,
    style: OFM_STYLE,
    center: o?.lat != null ? [o.lng, o.lat] : [-122.8, 47.6],
    zoom: o?.lat != null ? 9 : 5,
    attributionControl: { compact: true },
  })
  map.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'bottom-right')
  if (o?.lat != null) setPoint(o.lat, o.lng)
  map.on('click', (e) => setPoint(e.lngLat.lat, e.lngLat.lng))
})

onBeforeUnmount(() => map?.remove())

// Growing-area reuse: another oyster from the same water that already has a real pin.
const sameWater = computed(() => {
  const area = oyster.value?.growing_area?.trim().toLowerCase()
  if (!area) return null
  const candidates = allOysters.value.filter(
    (x) => x.id !== oyster.value.id && x.lat != null && x.growing_area?.trim().toLowerCase() === area,
  )
  return candidates.find((x) => !x.location_approx) || candidates[0] || null
})

// Debounced Nominatim search (the helper also enforces 1 req/sec).
let debounce = null
watch(query, (qq) => {
  clearTimeout(debounce)
  searchError.value = ''
  if (qq.trim().length < 3) {
    results.value = []
    return
  }
  debounce = setTimeout(async () => {
    searching.value = true
    try {
      results.value = await nominatimSearch(qq.trim())
    } catch {
      searchError.value = 'Search is napping. Tap the map instead.'
    } finally {
      searching.value = false
    }
  }, 700)
})

function pickResult(r) {
  setPoint(r.lat, r.lng, true)
  results.value = []
}

async function save() {
  if (!point.value) return
  saving.value = true
  await updateOyster(oyster.value.id, { lat: point.value.lat, lng: point.value.lng, location_approx: false })
  router.replace({ name: 'oyster', params: { id: oyster.value.id } })
}
</script>

<template>
  <div class="picker">
    <TopBar :title="oyster ? `Pin ${oyster.name}` : 'Pin'" back />
    <div class="search">
      <input v-model="query" class="input" type="search" placeholder="Search a bay, inlet, town…" />
      <div v-if="results.length || searching || searchError" class="results card">
        <p v-if="searching" class="small muted">Looking…</p>
        <p v-if="searchError" class="small muted">{{ searchError }}</p>
        <button v-for="r in results" :key="`${r.lat},${r.lng}`" class="res" @click="pickResult(r)">{{ r.label }}</button>
        <p class="attr small muted">
          Search by <a href="https://nominatim.openstreetmap.org/" target="_blank" rel="noopener">Nominatim</a>
          · © <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">OpenStreetMap</a> contributors
        </p>
      </div>
      <button v-if="sameWater" class="btn reuse" @click="setPoint(sameWater.lat, sameWater.lng, true)">
        Use the {{ oyster.growing_area }} pin
      </button>
    </div>
    <div ref="el" class="map" />
    <div class="bar">
      <span class="small muted">{{ point ? `${point.lat}, ${point.lng}` : 'Tap the map to drop a pin' }}</span>
      <div class="spacer" />
      <button class="btn primary big" :disabled="!point || saving" @click="save">Save pin</button>
    </div>
  </div>
</template>

<style scoped>
.picker { height: 100dvh; display: flex; flex-direction: column; }
.search { position: relative; padding: 0 16px 10px; z-index: 10; }
.results {
  position: absolute;
  left: 16px;
  right: 16px;
  top: 58px;
  max-height: 50vh;
  overflow-y: auto;
  padding: 6px;
}
.res {
  display: block;
  width: 100%;
  text-align: left;
  border: 0;
  background: none;
  padding: 12px;
  border-radius: 10px;
  cursor: pointer;
}
.res:hover { background: var(--surface-2); }
.attr { padding: 6px 12px 2px; margin: 0; }
.reuse { margin-top: 8px; background: var(--lemon); color: var(--ink); }
.map { flex: 1; }
.bar {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px calc(12px + var(--safe-bottom));
  background: var(--bg);
}
</style>
