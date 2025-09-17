#!/usr/bin/env bash
# dev_reg_events.sh — GET /devices/{id}/events (sourcing-friendly, with diagnostics)
# Source this file:  . ./dev_reg_events.sh [device_id]
#
# Requires env: hostname, api_version, access_key, secret_access_key, session_token
# Optional env:
#   aws_region (default us-east-1), service (default execute-api)
#   DEBUG=1       # print response headers
#   QUIET=0/1     # when 1, suppress pretty body output (still exports vars)

# --- preserve caller shell options; relax -e for sourcing friendliness ---
__DEVREG_GET_OLD_OPTS="$(set +o)"
set +e

fail() {
  echo "Error: $*" >&2
  # restore caller's shell opts before returning
  eval "$__DEVREG_GET_OLD_OPTS"; unset __DEVREG_GET_OLD_OPTS
  return 1 2>/dev/null || exit 1
}

# --- deps ---
for cmd in curl jq; do command -v "$cmd" >/dev/null || fail "Missing dependency: $cmd"; done

# --- defaults (overridable) ---
: "${aws_region:=us-east-1}"
: "${service:=execute-api}"
: "${DEBUG:=0}"
: "${QUIET:=0}"

# --- required envs ---
for v in hostname api_version access_key secret_access_key session_token; do
  [[ -n "${!v:-}" ]] || fail "Missing environment variable: $v"
done

# --- device id: arg or previously exported ---
DEVICE_ID="${1:-${device_registry_id:-}}"
[[ -n "$DEVICE_ID" ]] || fail "Provide device id as arg or set \$device_registry_id"

# --- call API (SigV4) with diagnostics; keep body clean (no --include) ---
tmpdir="$(mktemp -d)"; hdr="$tmpdir/headers.txt"; body="$tmpdir/body.txt"
code="$(
  curl -sS --http1.1 \
    --aws-sigv4 "aws:amz:${aws_region}:${service}" \
    -u "${access_key}:${secret_access_key}" \
    -H "x-amz-security-token: ${session_token}" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    "https://${hostname}/${api_version}/devices/${DEVICE_ID}/events" \
    -D "$hdr" -o "$body" -w '%{http_code}'
)"

# --- export diagnostics so subsequent sourced scripts can inspect them ---
export devreg_last_http_status="$code"
export devreg_last_headers="$hdr"
export devreg_last_body="$body"

echo "HTTP_STATUS=${code}"
if (( DEBUG )); then
  echo "=== HEADERS ==="
  cat "$hdr"
fi

# --- body output (pretty if JSON) ---
if (( QUIET == 0 )); then
  echo "=== BODY ==="
  if jq -e . >/dev/null 2>&1 <"$body"; then 
    jq . <"$body"; 
  else
    cat "$body";
  fi
fi

# --- parse useful fields and export them ---
device_state="$(jq -r '.device_state // .state // .status // empty' <"$body" 2>/dev/null || true)"
device_uuid="$(jq -r '.uuid // empty' <"$body" 2>/dev/null || true)"
certificate_link="$(jq -r '.provisioning_certificate.certificate_link // empty' <"$body" 2>/dev/null || true)"

export device_state device_uuid certificate_link

[[ -n "$device_state" ]] && echo "device_state=${device_state}"
[[ -n "$device_uuid" ]] && echo "uuid=${device_uuid}"
[[ -n "$certificate_link" ]] && echo "certificate_link=${certificate_link}"

# --- treat non-200 as an error to aid pipelines ---
if [[ "$code" != "200" ]]; then
  fail "GET ${DEVICE_ID} returned HTTP ${code}"
fi

# --- restore caller shell options and return ---
eval "$__DEVREG_GET_OLD_OPTS"
unset __DEVREG_GET_OLD_OPTS
return 0 2>/dev/null || exit 0

