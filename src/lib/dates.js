// visited_on is a local calendar date, never a UTC timestamp.
export function localToday() {
  const d = new Date()
  const pad = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}

export function formatDate(iso, opts = { month: 'short', day: 'numeric', year: 'numeric' }) {
  if (!iso) return ''
  const [y, m, d] = iso.slice(0, 10).split('-').map(Number)
  return new Date(y, m - 1, d).toLocaleDateString(undefined, opts)
}

export function relativeDay(iso) {
  if (!iso) return ''
  if (iso === localToday()) return 'Tonight'
  return formatDate(iso, { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' })
}
