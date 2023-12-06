## Bandlink-Supabase

[manage migrations](https://supabase.com/docs/reference/cli/supabase-migration)

### Version control

To update the DB or RPC calls you must create migration:
`supabase migration new <NAME>`

Then add manual updates and apply to DB:
`supabase migration up` (apply new changes) OR `supabase migration db reset` (start frest)

generate types:
`supabase gen types typescript --local  --schema public > types/supabase.ts`

# PR to `develop`

Merging a PR to `develop` will run all migrations against the hosted supabase instance. It will not run the `seed.sql` so all data is fine.
