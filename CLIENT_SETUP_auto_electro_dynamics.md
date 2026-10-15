# Auto Electro Dynamics — Client Setup Notes

This app is a per-client copy of the Edge Telematics facial-recognition system,
cloned from the ImageMakers deployment. Everything client-specific has been
re-namespaced for **Auto Electro Dynamics**.

## What was changed from the ImageMakers copy

1. **Database tables** — every table suffix changed from `_auto_electro_dynamics` to
   `_auto_electro_dynamics`. The 11 tables (all on the same shared Postgres
   server, no collision with other clients):
   - `users_facial_recognition_auto_electro_dynamics`
   - `drivers_auto_electro_dynamics`
   - `recognition_events_auto_electro_dynamics`
   - `recognition_events_latest_auto_electro_dynamics`
   - `audit_logs_auto_electro_dynamics`
   - `custom_fields_auto_electro_dynamics`
   - `driver_custom_field_values_auto_electro_dynamics`
   - `role_permissions_auto_electro_dynamics`
   - `trips_auto_electro_dynamics`
   - `pipeline_runs_auto_electro_dynamics`
   - `geozones_auto_electro_dynamics`
   Index/constraint names were updated to match (e.g. `uq_role_perm_auto_electro_dynamics`,
   `ix_trips_auto_electro_dynamics_vehicle_start`).

2. **Cloudflare R2 bucket** — default bucket changed to `auto-electro-dynamics`
   (in `config.py` and `app/services/storage_service.py`). Create this bucket in
   R2 before enrolling drivers.

3. **Admin seed email** — `admin@autoelectrodynamics.local`.

4. **FM-Track API key** — reset to a placeholder in both `load_trips.py` and
   `pipeline/load_trips.py` (the ImageMakers live key was removed). Paste this
   client's own FM-Track key before running the trips pipeline.

5. **Stale data removed** — `data/drivers.db` (an old SQLite artifact) was
   deleted so this client starts clean. Production uses Postgres.

## Creating the database tables

Either let the app create them automatically on first start (SQLAlchemy
`db.create_all()` runs in `app/__init__.py`), **or** run the provided DDL
explicitly against the shared Postgres server:

```bash
psql "postgresql://edge_admin:...@173.249.46.82:5432/postgres" -f SQL_create_all_tables.sql
```

`SQL_create_all_tables.sql` is idempotent (`IF NOT EXISTS` / `ON CONFLICT`) and
also seeds a default admin (`admin` / `Admin@1234` — change it after first login).

## Still to configure before go-live

- Create the `auto-electro-dynamics` R2 bucket.
- Set credentials via `.env` (recommended over the hardcoded fallbacks in
  `config.py`): `SECRET_KEY`, `DATABASE_URL`, `CF_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`,
  `R2_SECRET_ACCESS_KEY`, `R2_BUCKET=auto-electro-dynamics`.
- Paste this client's FM-Track API key in `load_trips.py` / `pipeline/load_trips.py`.
- Change the default admin password after first login.
