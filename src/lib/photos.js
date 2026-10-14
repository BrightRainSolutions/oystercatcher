import { get, set, del } from 'idb-keyval'

const FULL = 1600
const THUMB = 400

async function decode(file) {
  try {
    return await createImageBitmap(file, { imageOrientation: 'from-image' })
  } catch {
    // Older Safari: fall back to an <img>, which also honors EXIF orientation.
    const url = URL.createObjectURL(file)
    try {
      const img = new Image()
      img.src = url
      await img.decode()
      return img
    } finally {
      URL.revokeObjectURL(url)
    }
  }
}

function resize(source, longEdge) {
  const w = source.width
  const h = source.height
  const scale = Math.min(1, longEdge / Math.max(w, h))
  const canvas = document.createElement('canvas')
  canvas.width = Math.round(w * scale)
  canvas.height = Math.round(h * scale)
  const ctx = canvas.getContext('2d')
  ctx.imageSmoothingQuality = 'high'
  ctx.drawImage(source, 0, 0, canvas.width, canvas.height)
  return new Promise((resolve, reject) =>
    canvas.toBlob((b) => (b ? resolve(b) : reject(new Error('Could not encode photo'))), 'image/jpeg', 0.8),
  )
}

export async function processPhoto(file) {
  const bmp = await decode(file)
  const full = await resize(bmp, FULL)
  const thumb = await resize(bmp, THUMB)
  bmp.close?.()
  return { full, thumb }
}

const key = (id, kind) => `oc:photo:${id}:${kind}`
export const saveLocalPhoto = (id, { full, thumb }) => Promise.all([set(key(id, 'full'), full), set(key(id, 'thumb'), thumb)])
export const getLocalPhoto = (id, kind) => get(key(id, kind))
export const deleteLocalPhoto = (id) => Promise.all([del(key(id, 'full')), del(key(id, 'thumb'))])

// Object URLs for local blobs, kept for the life of the page so an <img>
// already showing one keeps working after the blob is deleted post-upload.
const objectUrls = new Map()
export async function localPhotoUrl(id, kind) {
  const k = key(id, kind)
  if (objectUrls.has(k)) return objectUrls.get(k)
  const blob = await get(k)
  if (!blob) return null
  const url = URL.createObjectURL(blob)
  objectUrls.set(k, url)
  return url
}

export const storagePaths = (visitId, photoId) => ({
  storage_path: `${visitId}/${photoId}.jpg`,
  thumb_path: `${visitId}/${photoId}_thumb.jpg`,
})
