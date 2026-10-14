import { ref, computed } from 'vue'
import { get, set } from 'idb-keyval'
import { supabase } from '../lib/supabase'

const session = ref(null)
const profiles = ref([])
const ready = ref(false)
let initPromise = null

// Used only if someone's profile row is missing a color (or hasn't loaded).
const FALLBACK_COLORS = ['#ff6b5a', '#2bb3a3', '#f2a91e', '#7a5cff', '#3f7a52', '#e05297', '#1d74a8', '#a8642a']
const fallbackColor = (id = '') => FALLBACK_COLORS[[...id].reduce((h, c) => (h * 31 + c.charCodeAt(0)) >>> 0, 7) % FALLBACK_COLORS.length]

async function loadProfiles() {
  if (!session.value) return
  const { data, error } = await supabase.from('profiles').select('*').order('display_name')
  if (!error && data) {
    profiles.value = data
    set('oc:profiles', data)
  } else {
    profiles.value = (await get('oc:profiles')) || profiles.value
  }
}

export function initAuth() {
  initPromise ||= (async () => {
    profiles.value = (await get('oc:profiles')) || []
    const { data } = await supabase.auth.getSession()
    session.value = data.session
    supabase.auth.onAuthStateChange((event, s) => {
      const wasSignedIn = !!session.value
      session.value = s
      if (s && (!wasSignedIn || event === 'SIGNED_IN')) loadProfiles()
    })
    if (session.value) loadProfiles()
    ready.value = true
  })()
  return initPromise
}

const user = computed(() => session.value?.user ?? null)
const me = computed(() => profiles.value.find((p) => p.id === user.value?.id) ?? null)
const byName = (a, b) => (a.display_name || '').localeCompare(b.display_name || '')

// Everyone in the family except me, alphabetical.
const others = computed(() =>
  profiles.value.filter((p) => p.id !== user.value?.id).map(withColor).sort(byName),
)

// Me first, then everyone else, so grouped bars always read in the same order.
const people = computed(() => {
  const list = []
  if (user.value) list.push(withColor(me.value ?? { id: user.value.id, display_name: 'Me' }))
  return [...list, ...others.value]
})

function withColor(p) {
  return p.color ? p : { ...p, color: fallbackColor(p.id) }
}

function profileFor(userId) {
  const p = profiles.value.find((x) => x.id === userId)
  if (p) return withColor(p)
  return { id: userId, display_name: userId === user.value?.id ? 'Me' : 'Family', color: fallbackColor(userId) }
}

/** Profiles for a set of user ids (e.g. whoever rated a tasting), me first, then by name. */
function peopleFor(userIds) {
  const ids = new Set([...userIds].filter(Boolean))
  const mine = user.value && ids.has(user.value.id) ? [profileFor(user.value.id)] : []
  const rest = [...ids].filter((id) => id !== user.value?.id).map(profileFor).sort(byName)
  return [...mine, ...rest]
}

// First word of a display name: short enough for chips when the whole family rated.
const shortName = (p) => (p?.display_name || '?').trim().split(/\s+/)[0]

async function signInWithPassword(email, password) {
  const { error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) throw error
}

async function sendMagicLink(email) {
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: { shouldCreateUser: false, emailRedirectTo: window.location.origin },
  })
  if (error) throw error
}

async function signOut() {
  await supabase.auth.signOut()
  session.value = null
}

export function useAuth() {
  return {
    session,
    user,
    me,
    others,
    people,
    peopleFor,
    shortName,
    profiles,
    ready,
    profileFor,
    loadProfiles,
    signInWithPassword,
    sendMagicLink,
    signOut,
  }
}
