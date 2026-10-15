<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import maplibregl from 'maplibre-gl'
import { getOysterBundle, loadOysters, updateOyster } from '../lib/data'
import { OFM_STYLE } from '../lib/geo'
import TopBar from '../components/TopBar.vue'
import LocationSearch from '../components/LocationSearch.vue'

const route = useRoute()
const router = useRouter()

const oyster = ref(null)
const allOysters = ref([])
const point = ref(null) // { lat, lng }
const loaded = ref(false)
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
  loaded.value = true

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
      <LocationSearch v-if="loaded" :initial="oyster?.growing_area || ''" @pick="setPoint($event.lat, $event.lng, true)" />
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
