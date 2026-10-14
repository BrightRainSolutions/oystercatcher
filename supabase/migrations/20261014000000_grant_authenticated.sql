-- Explicit table grants for signed-in users.
-- The project doesn't auto-expose new public tables to the Data API roles, so
-- without these, RLS policies never get a chance to run: every request from a
-- signed-in user fails with "permission denied". anon gets nothing here (it
-- only reads public.keepalive, granted in the init migration).

grant select, update on public.profiles to authenticated;

grant select, insert, update, delete on
  public.oysters,
  public.places,
  public.visits,
  public.tastings,
  public.ratings,
  public.photos
to authenticated;
