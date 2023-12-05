## Bandlink-Supabase

[manage migrations](https://supabase.com/docs/reference/cli/supabase-migration)
[manage RPC with version control](https://mansueli.hashnode.dev/streamlining-postgresql-function-management-with-supabase)

### RPC function version control

RPC functions are saved to the database for easy rollback.
They are created in the `archive.function_history` table.

- Run version control sql with `create_function_from_source` with the function as the params.
- Rollback is done with `rollback_function` with the function name.
