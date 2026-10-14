<script setup>
import { computed, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { useAuth } from '../composables/useAuth'
import { ATTRIBUTES, ALL_SCORES, OVERALL } from '../lib/attributes'
import { addPhoto, saveRating } from '../lib/data'
import ShellRating from './ShellRating.vue'
import ScoreSlider from './ScoreSlider.vue'
import ToggleSwitch from './ToggleSwitch.vue'
import CameraButton from './CameraButton.vue'
import PhotoImg from './PhotoImg.vue'
import PairedBars from './PairedBars.vue'

const props = defineProps({
  tasting: { type: Object, required: true },
  visitId: { type: String, required: true },
  photos: { type: Array, default: () => [] },
})
const emit = defineEmits(['changed'])

const { user, me, partner, profileFor } = useAuth()

const FIELDS = [...ALL_SCORES.map((a) => a.key), 'would_order_again', 'note']
const mine = computed(() => props.tasting.ratings?.find((r) => r.user_id === user.value?.id) ?? null)
const theirs = computed(() => props.tasting.ratings?.find((r) => r.user_id !== user.value?.id) ?? null)
const theirProfile = computed(() => (theirs.value ? profileFor(theirs.value.user_id) : partner.value))
const myColor = computed(() => me.value?.color || 'var(--coral)')

const form = reactive(Object.fromEntries(FIELDS.map((k) => [k, mine.value?.[k] ?? null])))
const details = ref(ATTRIBUTES.some((a) => form[a.key] != null))
const savedOnce = ref(!!mine.value)
const saving = ref(false)
const shooting = ref(false)

let timer = null
let dirty = false
watch(
  form,
  () => {
    dirty = true
    clearTimeout(timer)
    timer = setTimeout(save, 600)
  },
  { deep: true },
)

async function save() {
  if (!dirty) return
  dirty = false
  saving.value = true
  await saveRating(props.tasting.id, user.value.id, { ...form })
  savedOnce.value = true
  saving.value = false
}

onBeforeUnmount(() => {
  clearTimeout(timer)
  save()
})

const iHaveRated = computed(() => savedOnce.value && form.overall != null)

const compareRows = computed(() =>
  ALL_SCORES.map((a) => ({
    label: a.label,
    values: [
      { value: form[a.key], color: myColor.value },
      { value: theirs.value?.[a.key] ?? null, color: theirProfile.value?.color || 'var(--kelp)' },
    ],
  })),
)
const showCompare = ref(false)

async function onPhoto(file) {
  shooting.value = true
  try {
    await addPhoto(file, { visitId: props.visitId, tastingId: props.tasting.id })
    emit('changed')
  } finally {
    shooting.value = false
  }
}
</script>

<template>
  <article class="card rcard">
    <header class="head">
      <div>
        <h3>{{ tasting.oyster?.name || 'Mystery oyster' }}</h3>
        <p class="muted small sub">
          {{ [tasting.oyster?.grower, tasting.oyster?.growing_area].filter(Boolean).join(' · ') }}
        </p>
      </div>
      <span
        v-if="theirs?.overall"
        class="their-badge"
        :style="{ background: theirProfile?.color || 'var(--kelp)' }"
        :title="`${theirProfile?.display_name} gave it ${theirs.overall}`"
      >
        {{ theirProfile?.display_name?.slice(0, 1) }} · {{ theirs.overall }}
      </span>
    </header>

    <div class="overall">
      <ShellRating v-model="form.overall" :size="54" :color="myColor" />
      <div class="ends small muted">
        <span>{{ OVERALL.low }}</span><span>{{ OVERALL.high }}</span>
      </div>
    </div>

    <div class="row again">
      <ToggleSwitch
        :model-value="!!form.would_order_again"
        label="Would order again"
        @update:model-value="form.would_order_again = $event"
      />
      <div class="spacer" />
      <span v-if="saving" class="small muted">saving…</span>
      <span v-else-if="savedOnce" class="small saved">saved</span>
    </div>

    <button type="button" class="more" @click="details = !details">
      {{ details ? 'Fewer feelings' : 'More feelings' }}
      <svg viewBox="0 0 24 24" width="18" height="18" :class="{ flip: details }" aria-hidden="true">
        <path d="M6 9l6 6 6-6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" />
      </svg>
    </button>
    <div v-if="details" class="sliders">
      <ScoreSlider
        v-for="a in ATTRIBUTES"
        :key="a.key"
        v-model="form[a.key]"
        :label="a.label"
        :low="a.low"
        :high="a.high"
        :color="myColor"
      />
    </div>

    <textarea v-model.lazy="form.note" class="input note" rows="2" placeholder="Tasting notes, hot takes, regrets…" />

    <div class="row wrap foot">
      <CameraButton small label="Close-up" :busy="shooting" @file="onPhoto" />
      <div class="thumbs">
        <div v-for="p in photos" :key="p.id" class="thumb">
          <PhotoImg :photo-id="p.id" :path="p.thumb_path" />
        </div>
      </div>
    </div>

    <template v-if="theirs && iHaveRated">
      <button type="button" class="more" @click="showCompare = !showCompare">
        {{ showCompare ? 'Hide' : 'See' }} how you compare
      </button>
      <PairedBars v-if="showCompare" :rows="compareRows" />
    </template>
    <p v-else-if="theirs" class="small muted">Rate it to see {{ theirProfile?.display_name || 'their' }}'s full scores. No peeking.</p>
  </article>
</template>

<style scoped>
.rcard + .rcard { margin-top: 16px; }
.head { display: flex; align-items: flex-start; gap: 10px; justify-content: space-between; }
.head h3 { margin: 0; font-size: 1.35rem; }
.sub { margin: 2px 0 0; }
.their-badge {
  flex: none;
  color: #fff;
  font-weight: 800;
  font-size: 0.85rem;
  padding: 4px 10px;
  border-radius: 999px;
}
.overall { margin: 14px 0 6px; }
.ends { display: flex; justify-content: space-between; max-width: 290px; padding: 0 4px; }
.again { margin: 10px 0 4px; }
.saved { color: var(--kelp); font-weight: 700; }
.more {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  min-height: 44px;
  border: 0;
  background: none;
  color: var(--sea-3);
  font-weight: 800;
  padding: 0;
  cursor: pointer;
}
.more svg { transition: transform 0.2s ease; }
.more svg.flip { transform: rotate(180deg); }
.sliders { padding: 4px 0 8px; }
.note { margin-top: 8px; }
.foot { margin-top: 12px; }
.thumbs { display: flex; gap: 6px; flex-wrap: wrap; }
.thumb { width: 44px; height: 44px; border-radius: 10px; overflow: hidden; }
</style>
