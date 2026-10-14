<script setup>
import { computed, onMounted, ref } from 'vue'
import { loadOysters } from '../lib/data'
import { loadingLine } from '../lib/attributes'
import TopBar from '../components/TopBar.vue'

const oysters = ref([])
const loading = ref(true)
onMounted(async () => {
  oysters.value = await loadOysters()
  loading.value = false
})
const unpinned = computed(() => oysters.value.filter((o) => o.lat == null))
</script>

<template>
  <div>
    <TopBar title="Needs a pin" back="/dates" />
    <div v-if="loading" class="loading">{{ loadingLine() }}</div>
    <main v-else class="page">
      <p class="muted">Couch-time homework. Where do these grow?</p>
      <div v-if="!unpinned.length" class="empty"><span class="big-emoji">📍</span>Every oyster is on the map. Gold star.</div>
      <RouterLink v-for="o in unpinned" :key="o.id" :to="`/oyster/${o.id}/pin`" class="item card">
        <div>
          <strong>{{ o.name }}</strong>
          <div class="small muted">{{ [o.grower, o.growing_area].filter(Boolean).join(' · ') || 'Mysterious origins' }}</div>
        </div>
        <span class="badge-pin">Pin it</span>
      </RouterLink>
    </main>
  </div>
</template>

<style scoped>
.item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  min-height: 64px;
  margin-bottom: 10px;
  text-decoration: none;
}
</style>
