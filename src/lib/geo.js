// Haversine distance in km
export function distanceKm(a, b) {
  if (a?.lat == null || b?.lat == null) return Infinity
  const R = 6371
  const toRad = (d) => (d * Math.PI) / 180
  const dLat = toRad(b.lat - a.lat)
  const dLng = toRad(b.lng - a.lng)
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2
  return 2 * R * Math.asin(Math.sqrt(h))
}

let cachedPosition = null
export function getPosition({ timeout = 6000 } = {}) {
  if (cachedPosition && Date.now() - cachedPosition.at < 5 * 60_000) return Promise.resolve(cachedPosition)
  return new Promise((resolve) => {
    if (!navigator.geolocation) return resolve(null)
    navigator.geolocation.getCurrentPosition(
      (p) => {
        cachedPosition = { lat: p.coords.latitude, lng: p.coords.longitude, at: Date.now() }
        resolve(cachedPosition)
      },
      () => resolve(null),
      { enableHighAccuracy: false, timeout, maximumAge: 5 * 60_000 },
    )
  })
}

// Nominatim: max 1 request/sec (enforced here); callers also debounce input.
let lastNominatim = 0
let chain = Promise.resolve()
export function nominatimSearch(q) {
  const run = async () => {
    const wait = Math.max(0, lastNominatim + 1100 - Date.now())
    if (wait) await new Promise((r) => setTimeout(r, wait))
    lastNominatim = Date.now()
    const url = `https://nominatim.openstreetmap.org/search?format=jsonv2&limit=6&q=${encodeURIComponent(q)}`
    const res = await fetch(url, { headers: { 'Accept-Language': navigator.language || 'en' } })
    if (!res.ok) throw new Error(`Nominatim ${res.status}`)
    return (await res.json()).map((r) => ({
      label: r.display_name,
      lat: Number(r.lat),
      lng: Number(r.lon),
    }))
  }
  const p = chain.then(run, run)
  chain = p.catch(() => {})
  return p
}

export const OFM_STYLE = 'https://tiles.openfreemap.org/styles/liberty'
