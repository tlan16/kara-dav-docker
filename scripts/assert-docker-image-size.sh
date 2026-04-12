#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1

# Maximum allowed image size in MB (override via env var)
MAX_SIZE_MB="${MAX_SIZE_MB:-20}"

IMAGE_NAME="kara-dav-app"

# ── helpers ──────────────────────────────────────────────────────────────────
pass() { echo "  ✅  $*"; }
fail() { echo "  ❌  $*" >&2; exit 1; }

echo
echo "=== Docker image size report (limit: ${MAX_SIZE_MB} MB) ==="

echo "Building image..."
docker compose build app

# ── 1. Overall image size ─────────────────────────────────────────────────────
SIZE_BYTES=$(docker image inspect "${IMAGE_NAME}" \
  --format '{{.Size}}' 2>/dev/null) \
  || fail "Image '${IMAGE_NAME}' not found. Build may have failed."

SIZE_MB=$(( SIZE_BYTES / 1024 / 1024 ))

echo
echo "── Overall size ──────────────────────────────────────────────────────────"
echo "  Image : ${IMAGE_NAME}"
echo "  Size  : ${SIZE_MB} MB (${SIZE_BYTES} bytes)"

# ── 2. Layer-by-layer breakdown ───────────────────────────────────────────────
echo
echo "── Layer breakdown ───────────────────────────────────────────────────────"
printf "  %-12s  %s\n" "SIZE" "CREATED BY"
echo "  ------------  ----------------------------------------------------------------"

docker history --no-trunc --format '{{.Size}}\t{{.CreatedBy}}' "${IMAGE_NAME}" | \
  while IFS=$'\t' read -r layer_size layer_cmd; do
    # Truncate long commands for readability
    short_cmd="${layer_cmd:0:80}"
    [[ ${#layer_cmd} -gt 80 ]] && short_cmd="${short_cmd}…"
    printf "  %-12s  %s\n" "${layer_size}" "${short_cmd}"
  done

# ── 3. Threshold assertion ────────────────────────────────────────────────────
echo
echo "── Assertion ─────────────────────────────────────────────────────────────"
echo "  Limit : ${MAX_SIZE_MB} MB"

if (( SIZE_MB <= MAX_SIZE_MB )); then
  pass "Image size ${SIZE_MB} MB is within the ${MAX_SIZE_MB} MB limit"
else
  fail "Image size ${SIZE_MB} MB exceeds the ${MAX_SIZE_MB} MB limit"
fi

echo
echo "All assertions passed 🎉"
