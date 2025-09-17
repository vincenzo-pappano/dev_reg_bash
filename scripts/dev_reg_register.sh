#!/usr/bin/env bash

#  dev_reg_register.sh — Register device from JSON/<file>.json (array of devices)
#  Source this file:  . ./dev_reg_register.sh <file.json> [index]
#  Requires env: hostname, api_version, access_key, secret_access_key, session_token
#  Optional env: aws_region (default us-east-1), service (default execute-api), JSON_DIR (default JSON)
#  Optional env: DEBUG=1 to print headers; PRINT_PAYLOAD=1 to show request JSON.
#
#  Assume device ID: IOTONPAPPDEV01234567
#  The certificate file must already exist and must have been correctly populated
#  List of certificates
#  Associate a specific certificate with the charger via the UUID
#  Specify certificate index in list. User can also provid a JSON file containing a list with a single certificate
#  [
#    {
#      "serial_number": 0,
#      "firmware_version": "",
#      "created_date": "1756937206798",
#      "uuid": "IOTPAPPVIDEO0000007",
#      "customer_id": "multi-test",
#      "client_id": "multi-test-IOTPAPPVIDEO0000007",
#      "provisioning_certificate": {
#        "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURXVENDQWtHZ0F3SUJBZ0lVVlo0eE9PK1VibitCL0NHN3NpbGh2ekVjZmVBd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1RURkxNRWtHQTFVRUN3eENRVzFoZW05dUlGZGxZaUJUWlhKMmFXTmxjeUJQUFVGdFlYcHZiaTVqYjIwZwpTVzVqTGlCTVBWTmxZWFIwYkdVZ1UxUTlWMkZ6YUdsdVozUnZiaUJEUFZWVE1CNFhEVEkxTURrd016SXlNRFEwCk5sb1hEVFE1TVRJek1USXpOVGsxT1Zvd0hqRWNNQm9HQTFVRUF3d1RRVmRUSUVsdlZDQkRaWEowYVdacFkyRjAKWlRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTlhKOHdTeVpmSWRYVjd5QmJTMgoyRWhCalhOeVFoQWZrK0dzeDVmaHRLMHVUbE8wVmRNOW5aeXFPU1psWUJaWEsvMlgyUFU1ZzdielJKZDVQQitSCmcyaEhHa28zS3M2dzlaN1hDVnFCbUtIWFZocGRadUtOYU94aURIRXlQSDJzRHNVblp2YzN1S2UwZDBkZnNuemYKYjZVL2VFK3U1ck5KRWJDcE5XbkRnMHNEZHFBY3FuUk9lTlovbHBiNTg5Wlhrd1JMNk9KZ2N5bUZNaGF2OUJIZgpkWTZEL0lsM2dzcWh4U2paTmhBaExHSkF5VEF3MGZWRWY3bXFLZ0M1QS9VZEZvV3VNdkNGSnA5RmF3UG5OaEZqClB2b2R3bHVwclhDV2FRQWl5ck1jQ3lkL3p5ZDg0b3FsZWpIZStXL0JXNXJNUDlXNDdFY2s1aG52aThsSVJxN3kKUnZVQ0F3RUFBYU5nTUY0d0h3WURWUjBqQkJnd0ZvQVV0akl5eDJJajVBZFYwSDIxTVk0RjVOUFZEbzR3SFFZRApWUjBPQkJZRUZBSS8rUEorZm90WEpZVkZtUlBKcFFsWHd1QkxNQXdHQTFVZEV3RUIvd1FDTUFBd0RnWURWUjBQCkFRSC9CQVFEQWdlQU1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQW9NeHNrM1lrL2xwL3l2T0FWMDh6dUpNeFQKY3BwQkZvdldIUzMraDQzM2VPbHZHNCt3Zmg3RVFtOFg2VG5RUjkxOEhNa3N2enpLais0amZhanRyU2hpL3h0aAprbk51OXo2SnluSnpxeWF4bGt2WkpxU29zcjhpeUcxeXNLVEFVc3BGUmpMa3RWZGpoWGFwOENLSkRxRDl0UHl4CkF3NkJ2Y2JyYlU4NDQxTjZvSUZLU2ZxTkkzOGxEc1d6b2lnQlBHampYUW5CS1hxODNDQ21PYzFmN3ZJTTdtN1EKWEJ1WktpUTlqUkpteERKUVYySWY3MkEySmhpNlREdlRhTTNkcFlFMVROeFNheCtEeDRBZ1dBSzY0VmJoSlFxRwptb0pjUkluZVJqWHpkWWdRT0FjRXJZUnlGTGFZeFBLQUhPMEtkSWdVS3phK0loT2VVMllzazBTV2psVkgKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
#      }
#    },
#    {
#      "serial_number": 1,
#      "firmware_version": "",
#      "created_date": "1756937206968",
#      "uuid": "",
#      "customer_id": "multi-test",
#      "client_id": "multi-test-",
#      "provisioning_certificate": {
#        "certificate": "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURXVENDQWtHZ0F3SUJBZ0lVWU14WE42REtiSkg5VEl4c1pvUG4yT3laOXVVd0RRWUpLb1pJaHZjTkFRRUwKQlFBd1RURkxNRWtHQTFVRUN3eENRVzFoZW05dUlGZGxZaUJUWlhKMmFXTmxjeUJQUFVGdFlYcHZiaTVqYjIwZwpTVzVqTGlCTVBWTmxZWFIwYkdVZ1UxUTlWMkZ6YUdsdVozUnZiaUJEUFZWVE1CNFhEVEkxTURrd016SXlNRFEwCk5sb1hEVFE1TVRJek1USXpOVGsxT1Zvd0hqRWNNQm9HQTFVRUF3d1RRVmRUSUVsdlZDQkRaWEowYVdacFkyRjAKWlRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTEdxZHZETDNqWmlDdFFXQ0pHegpEZ0wwTFpnVFVPQnNQWWQ3alFNU0o5ZjFIT2IxUGRseWlmT0ZWK1RLTGQxSDRxMzJCS0Y2Zm9pdnFHbnFOREM2ClhGU3NjeUh1STd6NUx0clRTZi8xWGRSWFgzTkxOOGNTWFYzVkJnQlNmSXRxalM4TGdhTXFzRkIwMDVxOU5XQXkKVHh4VXdLREsrSGN0R1IwTnl0Wmk3eksyT09DU2xKSE8xQVhvcUliVjRZSWMzdFRkVzk2c2tBSzBxekxKUXRVSQp5MW5VVCtTUU5TMXNZM1pic3BQbGlrS3dRU3oyNFNIS1Q0ZnNwcFFEWDRFS2hHZ2NjQ0NxQWV1MFRNeW1nckpaCnluaXA4cTZPbTFxMFdGZng2MVhONFBBamNkaGc4RU1KdUx5dnRWR1hwdk9UejFpcDVscGNlaCtIaWRYOCtJeEEKNi9VQ0F3RUFBYU5nTUY0d0h3WURWUjBqQkJnd0ZvQVVxUVp3T2hyUFcrdDFxUVYvVUZBWFRJS2VvbDR3SFFZRApWUjBPQkJZRUZEVjBPU2lMOVEzNmIrU05ISDFUYjQ4WHJOb0hNQXdHQTFVZEV3RUIvd1FDTUFBd0RnWURWUjBQCkFRSC9CQVFEQWdlQU1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ0tjQ0hWYzB5MERHS2ZGbnoxOW90ck53SG4KWUxwd01wS1ViRVZ5MjZ5cXBycEEzK2Q3cXBCMEo3U1pOanhqOTlFM1MrenZ2UkFqL3pETWdVUkt6UEhBZ0V0UgpCTUhSeHN0d3BRNHFuYjlFK2wzV1l1dXZjQ3g5VVVRK1REZDN1cGViallDR1BLdXJzNkFqOEQyNlk0UUhUVFhhCktkb1RVTGt5Vmx6Rm9yemRNTzIrZXlYbUl5NGpLa1RySkxsdlJ3Um5KWDlHTXl2cTdmWHVZdjV5dXh3Q2oxaE4KdmR6WFpvZUR2dmJHYTJvZXJXQXdnaUg5NWtydDdlU0dNOVBHN3UvWmY5NWhhRkZrME1oNE9nZktuRmxLZmhqUAozTk5JWStkZ05rM0hORy9hM25pcEFWUENqNElVTjkwMEpoL09zaHp5OStOekhYTWtMQXlhZThpR2xXZ2YKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo="
#      }
#    },
#    {},
#    {},
#    {},
#  ]

# --- preserve caller shell options; relax -e for sourcing friendliness ---
__DEVREG_REG_OLD_OPTS="$(set +o)"
set +e

fail() { echo "Error: $*" >&2; return 1 2>/dev/null || exit 1; }

# --- deps ---
for cmd in curl jq; do command -v "$cmd" >/dev/null || fail "Missing dependency: $cmd"; done

# --- defaults (overridable) ---
: "${aws_region:=us-east-1}"
: "${service:=execute-api}"
: "${JSON_DIR:=JSON}"
: "${DEBUG:=1}"
: "${PRINT_PAYLOAD:=1}"

# --- args & JSON path ---
FILE_BASENAME="${1-}"
[[ -n "$FILE_BASENAME" ]] || fail "Usage: ${BASH_SOURCE[0]} <file.json> [index]"
[[ "$FILE_BASENAME" == *.json ]] || FILE_BASENAME="${FILE_BASENAME}.json"
INDEX="${2:-0}"
JSON_PATH="${JSON_DIR}/${FILE_BASENAME}"
[[ -r "$JSON_PATH" ]] || fail "Cannot read file: $JSON_PATH"

# --- required envs ---
for v in hostname api_version access_key secret_access_key session_token; do
  [[ -n "${!v:-}" ]] || fail "Missing environment variable: $v"
done

# --- validate array + pick element ---
len="$(jq 'length' "$JSON_PATH")" || fail "Device file must be a JSON array"
[[ "$INDEX" =~ ^[0-9]+$ ]] || fail "Index must be a non-negative integer"
(( INDEX < len )) || fail "Index $INDEX out of range (length=$len)"

# --- extract fields from array element ---
created_date="$(jq -r ".[$INDEX].created_date // empty" "$JSON_PATH")"
uuid="$(jq -r ".[$INDEX].uuid // empty" "$JSON_PATH")"
customer_id="$(jq -r ".[$INDEX].customer_id // empty" "$JSON_PATH")"
client_id="$(jq -r ".[$INDEX].client_id // empty" "$JSON_PATH")"
certificate="$(jq -r ".[$INDEX].provisioning_certificate.certificate // .[$INDEX].certificate // empty" "$JSON_PATH")"

missing=()
[[ -n "$created_date" ]] || missing+=("created_date")
[[ -n "$uuid" ]]         || missing+=("uuid")
[[ -n "$customer_id" ]]  || missing+=("customer_id")
[[ -n "$client_id" ]]    || missing+=("client_id")
[[ -n "$certificate" ]]  || missing+=("provisioning_certificate.certificate")
(( ${#missing[@]} == 0 )) || fail "Missing required fields at index $INDEX: ${missing[*]}"

# --- build payload (add your two properties as in original) ---
payload="$(
  jq -n \
    --arg created_date "$created_date" \
    --arg uuid "$uuid" \
    --arg customer_id "$customer_id" \
    --arg client_id "$client_id" \
    --arg cert "$certificate" \
    '{
      created_date: $created_date,
      uuid: $uuid,
      customer_id: $customer_id,
      client_id: $client_id,
      provisioning_certificate: { certificate: $cert },
      properties: { "MainBoardBarcode":"T5691-M0001", "PowerBoardBarcode":"T5691-P001" }
    }'
)"

if (( PRINT_PAYLOAD )); then
  echo "=== PAYLOAD ==="
  jq . <<<"$payload"
fi

# --- call API (SigV4) with diagnostics; keep body clean (no --include) ---
tmpdir="$(mktemp -d)"; hdr="$tmpdir/headers.txt"; body="$tmpdir/body.txt"
code="$(
  curl -sS --http1.1 \
    --aws-sigv4 "aws:amz:${aws_region}:${service}" \
    -u "${access_key}:${secret_access_key}" \
    -H "x-amz-security-token: ${session_token}" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json' \
    -X POST "https://${hostname}/${api_version}/devices/device-registration" \
    --data-binary "$payload" \
    -D "$hdr" -o "$body" -w '%{http_code}'
)"

echo "HTTP_STATUS=${code}"
if (( DEBUG )); then
  echo "=== HEADERS ==="
  cat "$hdr"
fi

# jq -e . is true only if the file:
#    parses as JSON and
#    the last value isn’t false or null
echo "=== BODY ==="
if jq -e . >/dev/null 2>&1 <"$body"; then
  jq . <"$body"
else
  cat "$body"
fi

# --- capture and export id (like Postman test) ---
device_registry_id="$(jq -r '.id // .device_id // .data.id // empty' <"$body")"
if [[ -n "$device_registry_id" ]]; then
  export device_registry_id
  export device_registry_uuid="$uuid"
  echo "registered_device_id=$device_registry_id"
else
  # export diagnostics so the next sourced script can inspect them if needed
  export devreg_last_http_status="$code"
  export devreg_last_headers="$hdr"
  export devreg_last_body="$body"
  fail "Could not parse device id from response."
fi

# --- export last-call diagnostics on success too (handy for chaining) ---
export devreg_last_http_status="$code"
export devreg_last_headers="$hdr"
export devreg_last_body="$body"

# --- restore caller shell options and return ---
eval "$__DEVREG_REG_OLD_OPTS"
unset __DEVREG_REG_OLD_OPTS
return 0 2>/dev/null || exit 0
