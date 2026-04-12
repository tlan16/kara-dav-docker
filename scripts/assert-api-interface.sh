#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1

docker compose down --volumes --remove-orphans
docker compose up -d --build --wait app

BASE_URL="http://localhost:8080"

# ── helpers ──────────────────────────────────────────────────────────────────
pass() { echo "  ✅  $*"; }
fail() { echo "  ❌  $*" >&2; exit 1; }

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass "$label: $actual"
  else
    fail "$label — expected '$expected', got '$actual'"
  fi
}

assert_json_field() {
  local label="$1" field="$2" expected="$3" json="$4"
  local actual
  actual=$(printf '%s' "$json" | jq -r "$field")
  assert_eq "$label" "$expected" "$actual"
}

echo
echo "=== GET /status.php ==="
response=$(curl -s -w '\n%{http_code}' "${BASE_URL}/status.php")
http_code=$(printf '%s' "$response" | tail -n1)
body=$(printf '%s' "$response" | sed '$d')

assert_eq   "HTTP status"                  "200"       "$http_code"
assert_json_field "installed"              ".installed"          "true"  "$body"
assert_json_field "maintenance"            ".maintenance"        "false" "$body"
assert_json_field "needsDbUpgrade"         ".needsDbUpgrade"     "false" "$body"
assert_json_field "productname"            ".productname"        "NextCloud" "$body"

echo
echo "All assertions passed 🎉"
