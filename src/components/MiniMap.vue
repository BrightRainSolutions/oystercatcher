<script setup>
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import maplibregl from 'maplibre-gl'
import { OFM_STYLE } from '../lib/geo'

const props = defineProps({
  lat: { type: Number, default: null },
  lng: { type: Number, default: null },
  zoom: { type: Number, default: 13 },
  editable: { type: Boolean, default: false },
  height: { type: String, default: '200px' },
  color: { type: String, default: '#ff6b5a' },
})
const emit = defineEmits(['update'])

const el = ref(null)
let map = null
let marker = null

function placeMarker(lng, lat) {
  if (lat == null || lng == null) return
  if (!marker) {
    marker = new maplibregl.Marker({ color: props.color, draggable: props.editable }).setLngLat([lng, lat]).addTo(map)
    marker.on('dragend', () => {
      const p = marker.getLngLat()
      emit('update', { lat: round(p.lat), lng: round(p.lng) })
    })
  } else {
    marker.setLngLat([lng, lat])
  }
}

const round = (n) => Math.round(n * 1e6) / 1e6

onMounted(() => {
  const hasPoint = props.lat != null && props.lng != null
  map = new maplibregl.Map({
    container: el.value,
    style: OFM_STYLE,
    center: hasPoint ? [props.lng, props.lat] : [-98, 39],
    zoom: hasPoint ? props.zoom : 2.5,
    interactive: props.editable,
    attributionControl: { compact: true },
  })
  if (hasPoint) placeMarker(props.lng, props.lat)
  if (props.editable) {
    map.on('click', (e) => {
      placeMarker(e.lngLat.lng, e.lngLat.lat)
      emit('update', { lat: round(e.lngLat.lat), lng: round(e.lngLat.lng) })
    })
  }
})

watch(
  () => [props.lat, props.lng],
  ([lat, lng]) => {
    if (!map || lat == null || lng == null) return
    placeMarker(lng, lat)
    if (!props.editable || map.getZoom() < 6) map.jumpTo({ center: [lng, lat], zoom: Math.max(map.getZoom(), props.zoom) })
  },
)

onBeforeUnmount(() => map?.remove())
</script>

<template>
  <div ref="el" class="minimap" :style="{ height }" />
</template>

<style scoped>
.minimap {
  width: 100%;
  border-radius: var(--radius);
  overflow: hidden;
  box-shadow: var(--shadow);
}
</style>
