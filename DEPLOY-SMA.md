# GLPI Deployment Notes

## Source

Forked from: https://github.com/glpi-project/glpi  
Baseline ref: `054011027235702ae1bb0d75f9daa2b324dde186`

## Build & Run

```bash
./tester-env deploy
```

The build requires `HOST_USER_ID` and `HOST_GROUP_ID` args to align container `www-data` UID/GID with the host user. These are pinned in `docker-compose.yaml` for the target environment.

Services:
- `app`: GLPI web app (PHP 8.4 / Apache) on ports `8080` (HTTP), `8090`, `9637`
- `db`: MariaDB 11.8 on internal port `3306`
- `mailpit`: Mail testing on port `8025`
- `dbgate`: DB admin UI on port `9000`
- `openldap`: LDAP for auth testing

The `tester-env` wrapper supports:

```bash
./tester-env deploy
./tester-env verify
./tester-env status
./tester-env logs
./tester-env stop
./tester-env reset
```

`./tester-env seed` is intentionally not implemented yet and returns non-zero.
The default installer users are deterministic, but realistic seeded tickets,
assets, entities, and users still require seed-engineer work before GLPI can be
marked `data_populated`.

GLPI currently does not support parallel scenario runs. The Compose file has
hardcoded `container_name` and host port directives, so `--run-id` and non-8080
`--port` values are rejected by the wrapper.

## First-Time Setup

Dependencies are pre-installed in the host-mounted volume (`vendor/`, `node_modules/`, `public/lib/`). If they are missing, run inside the container:

```bash
docker exec -u www-data glpi-app php bin/console dependencies install
```

Install the database schema via CLI (deterministic, no web wizard needed):

```bash
docker exec -u www-data glpi-app php bin/console database:install \
  --db-host=db --db-name=glpi --db-user=glpi --db-password=glpi \
  --default-language=en_GB --force --reconfigure --no-telemetry -n
```

## Credentials

Default users created by the installer:
- `glpi` / `admin123` (Super-Admin)
- `tech` / `tech`
- `normal` / `normal`
- `post-only` / `post-only`

The `glpi` password is reset after install to ensure determinism:

```bash
docker exec -u www-data glpi-app php bin/console user:reset_password glpi -p admin123 -n
```

## Browser Smoke Test

1. Open http://localhost:8080
2. Login with `glpi` / `admin123`
3. Navigate to **Assistance > Tickets**
4. Create a new ticket with title "Smoke Test Ticket"
5. Verify the ticket appears in the ticket list

## Mutation Smoke Test

Edit source under the host-mounted volume (e.g., `src/Central.php`) and reload the page. Changes are visible immediately because PHP is interpreted on each request.

Example: changing `__('Standard interface')` to `__('Mutated Standard interface')` in `src/Central.php` changes the browser tab title on the next request.

## Reset

```bash
./tester-env reset
./tester-env deploy
```

This returns the app to a clean state with deterministic credentials.

## Caveats

- The Dockerfile changes `www-data` UID/GID to match the host user. If the host UID differs from the pinned value in `docker-compose.yaml`, permission errors will occur. Adjust `HOST_USER_ID` and `HOST_GROUP_ID` build args as needed.
- GLPI writes logs and cache to `files/_log/` and `files/_cache/` on the host volume. These persist across resets because they are part of the bind mount, but the database is recreated on `docker compose down -v`.
