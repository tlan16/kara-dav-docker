# KaraDAV — SPC php-fpm + nginx:alpine-slim

Smallest viable production setup. No worker mode needed for 1-2 users.

## Estimated Image Size

| Component          | Size      |
|--------------------|-----------|
| nginx:alpine-slim  | ~11 MB    |
| SPC php-fpm binary | ~10–15 MB |
| freetype (runtime) | ~2 MB     |
| KaraDAV source     | ~0.5 MB   |
| **Total**          | **~25–30 MB** |

## Why ondemand pm?

`pm = ondemand` means php-fpm workers only exist while a request is active.
For 1-2 users: effectively 0 PHP processes (and ~0 MB PHP RAM) when nobody
is accessing the server. nginx stays alive but uses ~2–3 MB idle.

## Quick Start

```bash
docker compose up -d
docker compose logs -f   # wait for KaraDAV to write SECRET_KEY

docker compose exec app \
  php /var/www/karadav/init.php --user admin --password yourpassword --admin

# Open http://localhost:8080
```

## Build Time

First build: ~5–15 min (SPC downloads pre-built PHP 8.4 binaries; compiles from source as fallback).
Subsequent builds: seconds (Docker cache hits the spc-builder layer).

## First-User Setup

After the container starts for the first time, create an admin account:

```bash
docker compose exec app php /var/www/karadav/init.php \
  --user admin --password yourpassword --admin
```

## Disable Thumbnails (saves ~2 MB)

Set `ENABLE_THUMBNAILS = false` in config.local.php, then remove the
`apk add freetype` line from the Dockerfile.
