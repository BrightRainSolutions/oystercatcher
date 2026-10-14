<script setup>
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import maplibregl from 'maplibre-gl'
import { OFM_STYLE } from '../lib/geo'

const props = defineProps({
  origins: { type: Array, default: () => [] }, // oyster_stats_combined rows with lat/lng
  places: { type: Array, default: () => [] }, // places with visit_count
})

const router = useRouter()
const el = ref(null)
const showOrigins = ref(true)
const showPlaces = ref(true)
let map = null

// Sequential warm ramp: reads well over Liberty's blue water and pale land.
const RAMP =['#ffe7a3', '#ffc04a', '#ff8a4a', '#e2483b', '#9c1240']

const originsGeo = () => ({
  type: 'FeatureCollection',
  features: props.origins
    .filter((o) => o.lat != null && o.lng != null)
    .map((o) => ({
      type: 'Feature',
      geometry: { type: 'Point', coordinates: [Number(o.lng), Number(o.lat)] },
      properties: {
        id: o.oyster_id,
        name: o.name,
        area: o.growing_area || '',
        avg: o.avg_overall == null ? -1 : Number(o.avg_overall),
        count: o.tasting_count || 0,
      },
    })),
})

const placesGeo = () => ({
  type: 'FeatureCollection',
  features: props.places
    .filter((p) => p.lat != null && p.lng != null)
    .map((p) => ({
      type: 'Feature',
      geometry: { type: 'Point', coordinates: [Number(p.lng), Number(p.lat)] },
      properties: { id: p.id, name: p.name, count: p.visit_count || 0 },
    })),
})

const PLACE_PIN = `<svg xmlns="http://www.w3.org/2000/svg" width="56" height="68" viewBox="0 0 56 68">
  <path d="M28 66C28 66 6 42 6 26a22 22 0 0 1 44 0c0 16-22 40-22 40z" fill="#0b3a5b" stroke="#fff" stroke-width="4"/>
  <g stroke="#ffd23f" stroke-width="3.2" stroke-linecap="round" fill="none">
    <path d="M22 14v10a4 4 0 0 0 4 4v10M30 14v10a4 4 0 0 1-4 4M26 14v9"/>
    <path d="M36 14c-3 2-4 6-4 10h4v14"/>
  </g>
</svg>`

async function addPinImage() {
  const img = new Image(56, 68)
  img.src = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(PLACE_PIN)}`
  await img.decode()
  if (!map.hasImage('place-pin')) map.addImage('place-pin', img, { pixelRatio: 2 })
}

function fitAll() {
  const coords = [...originsGeo().features, ...placesGeo().features].map((f) => f.geometry.coordinates)
  if (!coords.length) return
  const b = coords.reduce((bb, c) => bb.extend(c), new maplibregl.LngLatBounds(coords[0], coords[0]))
  map.fitBounds(b, { padding: 60, maxZoom: 10, duration: 0 })
}

onMounted(() => {
  map = new maplibregl.Map({
    container: el.value,
    style: OFM_STYLE,
    center: [-110, 44],
    zoom: 3,
    attributionControl: { compact: true },
  })
  map.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'bottom-right')
  if (import.meta.env.DEV) window.__ocMap = map

  // 'style.load', not 'load': 'load' waits for every tile, which may never come on bar wifi.
  map.once('style.load', async () => {
    await addPinImage()
    map.addSource('origins', { type: 'geojson', data: originsGeo() })
    map.addSource('places', { type: 'geojson', data: placesGeo() })

    map.addLayer({
      id: 'origins',
      type: 'circle',
      source: 'origins',
      paint: {
        'circle-color': [
          'case',
          ['<', ['get', 'avg'], 0],
          '#9aa5ad',
          ['interpolate', ['linear'], ['get', 'avg'], 1, RAMP[0], 2, RAMP[1], 3, RAMP[2], 4, RAMP[3], 5, RAMP[4]],
        ],
        'circle-radius': ['interpolate', ['linear'], ['get', 'count'], 0, 6, 1, 9, 5, 15, 15, 22],
        'circle-stroke-color': '#ffffff',
        'circle-stroke-width': 2.5,
        'circle-opacity': 0.95,
      },
    })
    map.addLayer({
      id: 'places',
      type: 'symbol',
      source: 'places',
      layout: {
        'icon-image': 'place-pin',
        'icon-anchor': 'bottom',
        'icon-allow-overlap': true,
        'text-field': ['get', 'name'],
        'text-font': ['Noto Sans Bold'],
        'text-size': 12,
        'text-offset': [0, 0.4],
        'text-anchor': 'top',
        'text-optional': true,
      },
      paint: { 'text-color': '#0b3a5b', 'text-halo-color': '#fff', 'text-halo-width': 1.6 },
    })

    for (const id of ['origins', 'places']) {
      map.on('mouseenter', id, () => (map.getCanvas().style.cursor = 'pointer'))
      map.on('mouseleave', id, () => (map.getCanvas().style.cursor = ''))
    }
    map.on('click', 'origins', (e) => {
      const f = e.features?.[0]
      if (f) router.push({ name: 'oyster', params: { id: f.properties.id } })
    })
    map.on('click', 'places', (e) => {
      const f = e.features?.[0]
      if (f) router.push({ name: 'place', params: { id: f.properties.id } })
    })
    fitAll()
  })
})

watch(
  () => [props.origins, props.places],
  () => {
    if (!map?.getSource('origins')) return
    map.getSource('origins').setData(originsGeo())
    map.getSource('places').setData(placesGeo())
    fitAll()
  },
)

watch(showOrigins, (v) => map?.getLayer('origins') && map.setLayoutProperty('origins', 'visibility', v ? 'visible' : 'none'))
watch(showPlaces, (v) => map?.getLayer('places') && map.setLayoutProperty('places', 'visibility', v ? 'visible' : 'none'))

onBeforeUnmount(() => map?.remove())
</script>

<template>
  <div class="mapwrap">
    <div ref="el" class="map" />
    <div class="layers">
      <button class="layer" :class="{ on: showOrigins }" @click="showOrigins = !showOrigins">
        <span class="sw origin" /> Origins
      </button>
      <button class="layer" :class="{ on: showPlaces }" @click="showPlaces = !showPlaces">
        <span class="sw place" /> Places
      </button>
    </div>
    <div v-if="showOrigins" class="legend card small">
      <span>meh</span>
      <span class="ramp" :style="{ background: `linear-gradient(90deg, ${RAMP.join(',')})` }" />
      <span>marry it</span>
    </div>
  </div>
</template>

<style scoped>
.mapwrap { position: relative; height: 100%; }
.map { position: absolute; inset: 0; }
.layers {
  position: absolute;
  top: 12px;
  left: 12px;
  display: flex;
  gap: 8px;
}
.layer {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  min-height: 40px;
  padding: 0 14px;
  border: 0;
  border-radius: 999px;
  background: var(--surface);
  color: var(--muted);
  box-shadow: var(--shadow);
  font-weight: 700;
  cursor: pointer;
}
.layer.on { color: var(--text); }
.layer:not(.on) .sw { opacity: 0.3; }
.sw { width: 14px; height: 14px; display: inline-block; }
.sw.origin { border-radius: 50%; background: #e2483b; border: 2px solid #fff; box-shadow: 0 0 0 1px #0002; }
.sw.place { border-radius: 4px 4px 50% 50%; background: var(--sea); }
.legend {
  position: absolute;
  left: 12px;
  bottom: 28px;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
}
.ramp { width: 90px; height: 10px; border-radius: 999px; }
</style>
