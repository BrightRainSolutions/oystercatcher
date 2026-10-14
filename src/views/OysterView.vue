<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAuth } from '../composables/useAuth'
import { getOysterBundle } from '../lib/data'
import { ALL_SCORES, loadingLine, speciesLabel } from '../lib/attributes'
import { formatDate } from '../lib/dates'
import TopBar from '../components/TopBar.vue'
import MiniMap from '../components/MiniMap.vue'
import PairedBars from '../components/PairedBars.vue'
import PhotoImg from '../components/PhotoImg.vue'

const route = useRoute()
const { people } = useAuth()
const bundle = ref(null)
const loading = ref(true)

async function load() {
  bundle.value = await getOysterBundle(route.params.id)
  loading.value = false
}
onMounted(load)
watch(() => route.params.id, load)

const o = computed(() => bundle.value?.oyster)
const statFor = (pid) => bundle.value?.stats.find((s) => s.user_id === pid)

const rows = computed(() =>
  ALL_SCORES.map((a) => ({
    label: a.label,
    values: people.value.map((p) => ({ color: p.color, value: statFor(p.id)?.[`avg_${a.key}`] ?? null })),
  })),
)
const overallOf = (t, pid) => t.ratings?.find((r) => r.user_id === pid)?.overall ?? null
const thumbOf = (t) => t.photos?.[0]?.thumb_path || t.visit?.cover?.thumb_path || null
</script>

<template>
  <div>
    <TopBar :title="o?.name || ''" back />
    <div v-if="loading" class="loading">{{ loadingLine() }}</div>
    <main v-else-if="!o" class="page empty"><span class="big-emoji">🦪</span>No such oyster. Was it a dream?</main>

    <main v-else class="page stack">
      <section>
        <h1 class="name">{{ o.name }}</h1>
        <p class="muted facts">
          {{ [o.grower, o.growing_area, o.region, speciesLabel(o.species), o.cultivation].filter(Boolean).join(' · ') }}
        </p>
        <a v-if="o.oysterater_url" :href="o.oysterater_url" target="_blank" rel="noopener" class="small">On Oysterater ↗</a>
      </section>

      <section>
        <template v-if="o.lat != null">
          <MiniMap :lat="o.lat" :lng="o.lng" :zoom="8" height="180px" />
          <div class="row small pinrow">
            <span v-if="o.location_approx" class="muted">Approximate spot</span>
            <div class="spacer" />
            <RouterLink :to="`/oyster/${o.id}/pin`" class="btn">Move pin</RouterLink>
          </div>
        </template>
        <RouterLink v-else :to="`/oyster/${o.id}/pin`" class="needs card">
          <span class="badge-pin">Needs a pin</span>
          <span>Where does it grow? Tap to drop a pin.</span>
        </RouterLink>
      </section>

      <section v-if="bundle.stats.length" class="card">
        <div class="row legend">
          <h3>Our averages</h3>
          <div class="spacer" />
          <span v-for="p in people" :key="p.id" class="small" :style="{ color: p.color, fontWeight: 800 }">
            {{ p.display_name }} ({{ statFor(p.id)?.tasting_count || 0 }})
          </span>
        </div>
        <PairedBars :rows="rows" />
        <p class="small muted">
          <span v-for="p in people" :key="p.id">
            {{ p.display_name }} would order again:
            {{ statFor(p.id)?.would_order_again_pct != null ? `${statFor(p.id).would_order_again_pct}%` : '–' }}.
          </span>
        </p>
      </section>

      <section>
        <h3>Every time we've had it</h3>
        <p v-if="!bundle.tastings.length" class="muted">Never! Fix that.</p>
        <RouterLink v-for="t in bundle.tastings" :key="t.id" :to="`/visit/${t.visit.id}`" class="hist card">
          <div class="th"><PhotoImg :path="thumbOf(t)" /></div>
          <div class="hmeta">
            <strong>{{ t.visit.place?.name || 'Home' }}</strong>
            <div class="small muted">{{ formatDate(t.visit.visited_on) }}</div>
          </div>
          <div class="overalls">
            <span v-for="p in people" :key="p.id" class="ov" :style="{ background: p.color }">
              {{ overallOf(t, p.id) ?? '–' }}
            </span>
          </div>
        </RouterLink>
      </section>
    </main>
  </div>
</template>

<style scoped>
.name { font-size: 2.4rem; margin: 0; }
.facts { margin: 4px 0; }
.pinrow { margin-top: 8px; }
.needs {
  display: flex;
  flex-direction: column;
  gap: 8px;
  align-items: flex-start;
  text-decoration: none;
  border: 3px dashed var(--lemon);
}
.legend { gap: 8px; margin-bottom: 8px; }
.legend h3 { margin: 0; }
.hist {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px;
  margin-bottom: 10px;
  text-decoration: none;
}
.th { width: 64px; height: 64px; border-radius: 12px; overflow: hidden; flex: none; }
.hmeta { flex: 1; min-width: 0; }
.overalls { display: flex; gap: 6px; }
.ov {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  border-radius: 50%;
  color: #fff;
  font-weight: 800;
}
</style>
