-- New rating attribute: Smell of the Sea (1-5, nullable like the others).
alter table public.ratings
  add column smell_of_the_sea smallint check (smell_of_the_sea between 1 and 5);

-- Add its per-person average to oyster_stats. New view columns must go at
-- the end for `create or replace view`.
create or replace view public.oyster_stats with (security_invoker = true) as
select
  t.oyster_id,
  r.user_id,
  round(avg(r.overall)::numeric, 2)                              as avg_overall,
  round(avg(r.brininess)::numeric, 2)                            as avg_brininess,
  round(avg(r.sweetness)::numeric, 2)                            as avg_sweetness,
  round(avg(r.creaminess)::numeric, 2)                           as avg_creaminess,
  round(avg(r.minerality)::numeric, 2)                           as avg_minerality,
  round(avg(r.brightness)::numeric, 2)                           as avg_brightness,
  round(avg(r.texture)::numeric, 2)                              as avg_texture,
  round(avg(r.size)::numeric, 2)                                 as avg_size,
  count(*)::int                                                  as tasting_count,
  max(v.visited_on)                                              as last_tasted,
  round(100.0 * avg(case when r.would_order_again then 1.0
                         when r.would_order_again = false then 0.0 end), 0) as would_order_again_pct,
  round(avg(r.smell_of_the_sea)::numeric, 2)                     as avg_smell_of_the_sea
from public.ratings r
join public.tastings t on t.id = r.tasting_id
join public.visits v   on v.id = t.visit_id
group by t.oyster_id, r.user_id;
