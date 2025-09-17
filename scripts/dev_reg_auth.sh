#!/usr/bin/env bash
# dev_reg_auth.sh — source this file:  . ./dev_reg_auth.sh <MFA_CODE>
# Requires: hostname, api_version, username, password (we provide safe defaults)
# Exports: access_key, secret_access_key, session_token (+ AWS_* mirrors)

# Save current shell options so we can restore them before returning
__DEVREG_OLD_OPTS="$(set +o)"
# Turn on strict just for this script's work
# set -euo pipefail is a common “strict mode” for Bash.
#    -e (errexit): exit the shell immediately if any simple command exits non-zero.
#    -u (nounset): treat unset variables as an error (use ${var:-default} to allow missing).
#    -o pipefail: a pipeline fails if any command in it fails (by default only the last command’s status is used).
# Why use it: catches silent failures early and stops the script before doing more damage.
set -euo pipefail

# ----- defaults (caller can override before sourcing) -----
# You can override any of these before sourcing, e.g. SHOW_SECRETS=0 . ./dev_reg_auth.sh 123456
: "${hostname:=ext-api.device-registry.i2p2.iotecha.com}"
: "${api_version:=v1}"
: "${username:=device-registry-prod-vpappano}"
: "${password:=BpHY6RGWQrxoLziB}"
: "${duration:=43200}"
: "${flashing_sessions_limit:=8}"
: "${SHOW_SECRETS:=1}"   # set to 1 to print full secrets; 0 masks them
: "${DEBUG:=1}"          # set to 1 to echo headers/status

# ----- helpers -----

# function die()
#
# print an error to stderr, then:
#    return 1 if sourced (return works inside a sourced file/function),
#    otherwise exit 1 (when run as a script).
#
# Net effect:
#    When used inside a function or a sourced library: it returns 1 to the caller.
#    When used in a standalone executed script (where return isn’t valid): it exits 1.
die() {
  echo "Error: $*" >&2
  if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
    return 1   # sourced context or called from another script
  else
    exit 1     # running as the main script
  fi
}

# function mask()
# receives a string as an argument, and creates a local string called s
# shows first 4 and last 4 characters is string is longer than 8
# otherwise show the complete string
# Note:
#    "${1-}" parameter expansion
#    The - form means: use $1 if it is set, otherwise use an empty string
#    This avoids an error under 'set -u' (unbound variable) if the function is called without an argument
#    The quotes "" prevent word splitting and gobbling 
mask() { local s="${1-}"; local n=${#s}; (( n>8 )) && printf '%s…%s' "${s:0:4}" "${s: -4}" || printf '%s' "$s"; }

# ----- args ---------------------------------------------------------------
MFA="${1-}"
[[ -n "$MFA" ]] || die "Usage: . $0 <MFA_CODE>"

# ----- deps ---------------------------------------------------------------
for cmd in jq curl; do command -v "$cmd" >/dev/null || die "Missing dependency: $cmd"; done

# ----- required envs ------------------------------------------------------
# {{ ... ]] buil-in test
# -n STRING: true if STRING has non-zero length
# $"{!v}": indirect expansion (as opposed to $"{v}" -- for instance, if v=$username, it expands to the value of $username
# $"{!v:-}" use default if unset or empty
# Note: $"{!v:-}" use emtpry string if unset 
for v in hostname api_version username password; do [[ -n "${!v:-}" ]] || die "Missing env: $v"; done

# ----- request -----
# create a directory in /tmp (for instance /tmp/tmp.abcd234)
# create paths for headers and body
tmpdir="$(mktemp -d)"; hdr="$tmpdir/headers.txt"; body="$tmpdir/body.json"


# --arg grab parameter as a string
# --argjson grab parameter as a number
# {
#    "username": "...",
#    "password": "...",
#    "mfa_code": "...",
#    "duration": 43200,
#    "flashing_sessions_limit": 8
# }
payload="$(jq -n \
   --arg username "$username" \
   --arg password "$password" \
   --arg mfa "$MFA" \
   --argjson duration "$duration" \
   --argjson flashing_sessions_limit "$flashing_sessions_limit" \
   '{
      username:$username,
      password:$password,
      mfa_code:$mfa,
      duration:$duration,
      flashing_sessions_limit:$flashing_sessions_limit
   }'
)"

# -H creates the request's headers
# -payload: the request's body
# -D capture the response headers into /tmp/tmp.xxx/headers.txt
# -o capture the response body into /tmp/tmp.xxx/body.json
# -w print HTTP status code
code="$(
  curl -sS --http1.1 --location \
    -H 'Content-Type: application/json' \
    --json "$payload" \
    "https://${hostname}/${api_version}/authorize" \
    -D "$hdr" -o "$body" -w '%{http_code}'
)"

(( DEBUG )) && { echo -e "\nHTTP_STATUS=$code"; echo -e "\n=== HEADERS ==="; cat "$hdr"; }

AUTH_JSON="$(cat "$body" 2>/dev/null || true)"    # print the bode to the AUTH_JSON here-string

# If error (any of the three $AUTH_JSON fields are empty), print debugging/troubleshooting information
if ! jq -e '.access_key and .secret_access_key and .session_token' \
        >/dev/null 2>&1 <<<"$AUTH_JSON"
then
  echo "Auth response (HTTP $code):"
  # Try to pretty-print the JSON; if that fails, dump the raw body file.
  if pretty=$(jq . <<<"$AUTH_JSON" 2>/dev/null); then
    printf '%s\n' "$pretty"
  else
    cat "$body"
  fi
  die "Could not extract credentials"
fi

# ----- export creds -----
export access_key secret_access_key session_token
access_key="$(jq -r '.access_key' <<<"$AUTH_JSON")"
secret_access_key="$(jq -r '.secret_access_key' <<<"$AUTH_JSON")"
session_token="$(jq -r '.session_token' <<<"$AUTH_JSON")"

# Mirrors for AWS tools (if using AWS compliant tools)
export AWS_ACCESS_KEY_ID="$access_key"
export AWS_SECRET_ACCESS_KEY="$secret_access_key"
export AWS_SESSION_TOKEN="$session_token"

# ----- output (masked by default) -----
echo
if (( SHOW_SECRETS )); then
  echo "access_key            : $access_key"
  echo "secret_access_key     : $secret_access_key"
  echo "session_token         : $session_token"
else
  echo "access_key            : $(mask "$access_key")"
  echo "secret_access_key     : $(mask "$secret_access_key")"
  echo "session_token         : $(mask "$session_token")"
fi
echo "AWS_ACCESS_KEY_ID     : $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY : $(mask "$AWS_SECRET_ACCESS_KEY")"
echo "AWS_SESSION_TOKEN     : $(mask "$AWS_SESSION_TOKEN")"
echo
echo "Auth OK. access_key / secret_access_key / session_token exported."
echo

# Restore caller's shell options to keep interactive completion happy
eval "$__DEVREG_OLD_OPTS"
unset __DEVREG_OLD_OPTS
return 0 2>/dev/null || exit 0



#code="$(
#  curl -sS --http1.1 --location \
#    -H 'Content-Type: application/json' \
#    --data "$(jq -n \
#      --arg username "$username" \
#      --arg password "$password" \
#      --arg mfa "$MFA" \
#      --argjson duration "$duration" \
#      --argjson flashing_sessions_limit "$flashing_sessions_limit" \
#      '{username:$username, password:$password, mfa_code:$mfa, duration:$duration, flashing_sessions_limit:$flashing_sessions_limit}')" \
#    "https://${hostname}/${api_version}/authorize" \
#    -D "$hdr" -o "$body" -w '%{http_code}'
#)"

# Extract access_key, secret_access_key, and session_token from AUTH_JSON and return true only if they exist and are not null/false
# -e: exit with success if the expression is true, failure otherwise
# if failure, print HTTP reponse code and body (jq pretty print or raw print on failure) ...
# ... and print error message
#jq -e '.access_key and .secret_access_key and .session_token' >/dev/null 2>&1 <<< "$AUTH_JSON" \
#  || { echo "Auth response (HTTP $code):"; (jq . <<<"$AUTH_JSON" 2>/dev/null || cat "$body"); die "Could not extract credentials"; }
