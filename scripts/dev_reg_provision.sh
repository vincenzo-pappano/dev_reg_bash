#!/usr/bin/env bash
# dev_reg_provision.sh — Provision a device (sourcing-friendly)
# Source this file:  . ./dev_reg_provision.sh [device_id]
#
# Requires env: hostname, api_version, access_key, secret_access_key, session_token
# Optional env:
#   aws_region   (default us-east-1),
#   service      (default execute-api)
#   DEBUG=1          # print response headers
#   PRINT_BODY=1     # echo the request body before sending
#   PROVISION_BODY   # JSON string to use as body (defaults to '{}')

# --- preserve caller shell options; relax -e for sourcing friendliness ---
__DEVREG_PROV_OLD_OPTS="$(set +o)"
set +e

fail() { echo "Error: $*" >&2; eval "$__DEVREG_PROV_OLD_OPTS"; unset __DEVREG_PROV_OLD_OPTS; return 1 2>/dev/null || exit 1; }

# --- deps ---
for cmd in curl jq; do command -v "$cmd" >/dev/null || fail "Missing dependency: $cmd"; done

# --- defaults (overridable) ---
: "${aws_region:=us-east-1}"
: "${service:=execute-api}"
: "${DEBUG:=0}"
: "${PRINT_BODY:=0}"

# --- required envs ---
for v in hostname api_version access_key secret_access_key session_token; do
  [[ -n "${!v:-}" ]] || fail "Missing environment variable: $v"
done

# --- device id: arg or previously exported device_registry_id ---
# If $1 is set and not empty
#    DEVICE_ID="$1" and the inner bit isn’t evaluated.
# Otherwise, evaluate ${device_registry_id:-}:
#    If device_registry_id is set and not empty
#       DEVICE_ID="$device_registry_id".
#    Else
#       DEVICE_ID="" (empty string).
#
# What it does “Use the first non-empty value among: the first positional argument, then device_registry_id, otherwise use empty.”
# Because of :-, empty strings count as “missing.” (If you wanted to treat only unset as missing and allow empty strings, you’d use - instead of :-.)
# Examples
#    ./dev_reg_provisioning.sh ABC → DEVICE_ID="ABC".
#    ./dev_reg_provisioning.sh     → with device_registry_id="XYZ" → DEVICE_ID="XYZ".
#    ./dev_reg_provisioning.sh     → with device_registry_id="" (or unset) → DEVICE_ID="".
DEVICE_ID="${1:-${device_registry_id:-}}"
[[ -n "$DEVICE_ID" ]] || fail "Provide a device id as arg or set \$device_registry_id"

# --- request body (keep '{}' by default to avoid backend 500s) ---
if [[ -n "${PROVISION_BODY:-}" ]]; then
  body_payload="$PROVISION_BODY"
else
  body_payload='{}'
fi

# Validate body is JSON (empty is also ok)
if [[ -n "$body_payload" ]]; then
  echo "$body_payload" | jq -e . >/dev/null 2>&1 || fail "PROVISION_BODY is not valid JSON"
fi
(( PRINT_BODY )) && { echo "=== REQUEST BODY ==="; [[ -n "$body_payload" ]] && jq . <<<"$body_payload" || echo "(empty)"; }

# --- call API (SigV4) with diagnostics; keep body clean (no --include) ---
tmpdir="$(mktemp -d)"; hdr="$tmpdir/headers.txt"; resp_body="$tmpdir/body.txt"
code="$(
  curl -sS --http1.1 \
    --aws-sigv4 "aws:amz:${aws_region}:${service}" \
    -u "${access_key}:${secret_access_key}" \
    -H "x-amz-security-token: ${session_token}" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -X POST "https://${hostname}/${api_version}/devices/${DEVICE_ID}/provision" \
    --data-binary "$body_payload" \
    -D "$hdr" -o "$resp_body" -w '%{http_code}'
)"

# Export diagnostics so downstream scripts can inspect
export devreg_last_http_status="$code"
export devreg_last_headers="$hdr"
export devreg_last_body="$resp_body"

echo "HTTP_STATUS=${code}"
if (( DEBUG )); then
  echo "=== HEADERS ==="
  cat "$hdr"
fi
echo "=== BODY ==="
if [[ -s "$resp_body" ]]; then
  if jq -e . >/dev/null 2>&1 <"$resp_body"; then jq . <"$resp_body"; else cat "$resp_body"; fi
else
  echo "(empty)"
fi

# Consider 200 or 202 as success for this endpoint
if [[ "$code" != "200" && "$code" != "202" ]]; then
  fail "Provision request did not succeed (HTTP $code)"
fi

# --- restore caller shell options and return ---
eval "$__DEVREG_PROV_OLD_OPTS"
unset __DEVREG_PROV_OLD_OPTS
return 0 2>/dev/null || exit 0

