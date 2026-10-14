// Renders the app icons from the oystercatcher SVG. Run: npm run icons
import sharp from 'sharp'
import { readFile } from 'node:fs/promises'
import { fileURLToPath } from 'node:url'

const bird = (await readFile(new URL('../src/assets/oystercatcher.svg', import.meta.url), 'utf8'))
  .match(/<g id="bird">[\s\S]*<\/g>/)[0]

// rounded = favicon-style tile; square = full-bleed (iOS rounds it, maskable safe zone)
const tile = ({ rounded, scale }) => {
  const off = (512 - 512 * scale) / 2
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
    <rect width="512" height="512" ${rounded ? 'rx="112"' : ''} fill="#0b3a5b"/>
    <circle cx="256" cy="256" r="${196 * scale + (rounded ? 0 : 20)}" fill="#13557f"/>
    <g transform="translate(${off - 12 * scale} ${off - 10 * scale}) scale(${scale})">${bird}</g>
  </svg>`
}

const out = async (svg, size, file) => {
  await sharp(Buffer.from(svg)).resize(size, size).png().toFile(fileURLToPath(new URL(`../public/${file}`, import.meta.url)))
  console.log('wrote', file)
}

await out(tile({ rounded: true, scale: 1 }), 192, 'pwa-192.png')
await out(tile({ rounded: true, scale: 1 }), 512, 'pwa-512.png')
await out(tile({ rounded: false, scale: 0.78 }), 512, 'pwa-maskable-512.png')
await out(tile({ rounded: false, scale: 0.9 }), 180, 'apple-touch-icon.png')
