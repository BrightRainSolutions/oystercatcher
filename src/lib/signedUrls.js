import { supabase } from './supabase'

const TTL = 60 * 60 // seconds
const cache = new Map() // path -> { url, expires }
const inflight = new Map()

export async function signedUrl(path) {
  if (!path) return null
  const hit = cache.get(path)
  if (hit && hit.expires > Date.now() + 60_000) return hit.url
  if (inflight.has(path)) return inflight.get(path)
  const p = supabase.storage
    .from('photos')
    .createSignedUrl(path, TTL)
    .then(({ data, error }) => {
      if (error || !data) return null
      cache.set(path, { url: data.signedUrl, expires: Date.now() + TTL * 1000 })
      return data.signedUrl
    })
    .catch(() => null)
    .finally(() => inflight.delete(path))
  inflight.set(path, p)
  return p
}
