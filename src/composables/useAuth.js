import { ref, computed } from 'vue'
import { get, set } from 'idb-keyval'
import { supabase } from '../lib/supabase'

const session = ref(null)
const profiles = ref([])
const ready = ref(false)
let initPromise = null

const FALLBACK_COLORS = ['#ff6b5a', '#2bb3a3']

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
const partner = computed(() => profiles.value.find((p) => p.id !== user.value?.id) ?? null)

// Me first, then partner, so paired bars always read the same way round.
const people = computed(() => {
  const list = []
  if (user.value) list.push(me.value ?? { id: user.value.id, display_name: 'Me', color: FALLBACK_COLORS[0] })
  if (partner.value) list.push(partner.value)
  return list
})

function profileFor(userId) {
  const p = profiles.value.find((x) => x.id === userId)
  if (p) return p
  const i = userId === user.value?.id ? 0 : 1
  return { id: userId, display_name: i === 0 ? 'Me' : 'Them', color: FALLBACK_COLORS[i] }
}

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
    partner,
    people,
    profiles,
    ready,
    profileFor,
    loadProfiles,
    signInWithPassword,
    sendMagicLink,
    signOut,
  }
}
