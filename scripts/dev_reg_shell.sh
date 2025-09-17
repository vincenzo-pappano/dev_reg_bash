#!/usr/bin/env bash
# device_registry_shell.sh
# Pure Bash interactive shell that wraps dev_reg_* scripts.
# It will attempt to source a script and call its 'main' function if it exists.
# If no 'main' is found, it will execute the script directly.
#
# Usage: ./device_registry_shell.sh
#        devreg> help
#        devreg> auth --mfa 123456 --json creds.json
#        devreg> register --index 0 --json device_certificate.json
#        devreg> provision --json device.json
#        devreg> events --json device.json
#        devreg> get-state --json device.json
#        devreg> setvar JSON_FILE path/to/file.json
#        devreg> peek-index 0  # preview JSON entry 0 (no side effects)
#        devreg> history
#        devreg> exit
#
# Notes:
# - The shell keeps a few convenience variables you can set once and reuse:
#   - JSON_FILE, INDEX, MFA, EXTRA_ARGS
# - Commands accept additional arguments; they are passed through to the underlying script.
# - Scripts are run in a subshell, so their variables won't leak into the shell state.
# - Expected scripts (same directory as this shell):
#   - dev_reg_auth.sh, dev_reg_register.sh, dev_reg_provision.sh,
#   - dev_reg_events.sh, dev_reg_get_state.sh

set -Euo pipefail

# ---------- Paths ----------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
declare -A CMD_TO_SCRIPT=(
  ["auth"]="$SCRIPT_DIR/dev_reg_auth.sh"
  ["register"]="$SCRIPT_DIR/dev_reg_register.sh"
  ["provision"]="$SCRIPT_DIR/dev_reg_provision.sh"
  ["events"]="$SCRIPT_DIR/dev_reg_events.sh"
  ["get-state"]="$SCRIPT_DIR/dev_reg_get_state.sh"
)

# ---------- Shell State ----------
JSON_FILE="${JSON_FILE:-}"
INDEX="${INDEX:-0}"
MFA="${MFA:-}"
EXTRA_ARGS="${EXTRA_ARGS:-}"

HISTFILE="${HISTFILE:-$SCRIPT_DIR/.devreg_history}"
HISTCONTROL=ignoreboth
HISTSIZE=5000
SAVEHIST=5000

# Enable readline editing and completion if interactive
if [[ -t 0 ]]; then
  bind 'set editing-mode emacs' >/dev/null 2>&1 || true
  bind 'TAB: complete'         >/dev/null 2>&1 || true
fi

# ---------- Helpers ----------
_exists() { command -v -- "$1" >/dev/null 2>&1; }

color() { # color <code> <text>
  local code="$1"; shift
  printf "\033[%sm%s\033[0m" "$code" "$*"
}

cecho() { # cecho <color_code> <msg...>
  local code="$1"; shift
  color "$code" "$*"; printf "\n"
}

err() { cecho "31" "ERROR: $*"; }
ok()  { cecho "32" "$*"; }
info(){ cecho "36" "$*"; }

# Safely run a dev_reg_* script:
#  - Prefer sourcing and calling 'main' if it exists (inside a subshell).
#  - Fallback: execute the script directly with bash.
run_script() {
  local script="$1"; shift || true
  if [[ ! -f "$script" ]]; then
    err "Script not found: $script"
    return 1
  fi

  # Subshell to avoid leaking any variables/aliases into our shell.
  (
    set -Euo pipefail
    # Export convenience variables so scripts can pick them up (if they support them).
    export JSON_FILE INDEX MFA
    # shellcheck source=/dev/null
    source "$script"
    if declare -F main >/dev/null 2>&1; then
      main "$@"
    else
      # No 'main' found; try running the file directly as a script.
      exec bash "$script" "$@"
    fi
  )
}

# ---------- Built-in Commands ----------
help_cmd() {
  cat <<'EOF'
Available commands:
  auth [args...]        - Authenticate (uses dev_reg_auth.sh)
  register [args...]    - Register a device (uses dev_reg_register.sh)
  provision [args...]   - Provision a device (uses dev_reg_provision.sh)
  events [args...]      - Fetch/stream events (uses dev_reg_events.sh)
  get-state [args...]   - Get device state (uses dev_reg_get_state.sh)

Utility:
  setvar NAME VALUE     - Set a convenience variable (JSON_FILE, INDEX, MFA, EXTRA_ARGS)
  show                  - Show current shell variables
  peek-index N          - Print entry N from $JSON_FILE (non-destructive; requires jq)
  history               - Show command history
  help                  - This help
  exit / quit           - Leave the shell

Notes:
- Any extra tokens after the command are passed through to the underlying script.
- The shell also appends set convenience vars:
    * If JSON_FILE is set, it adds: --json "$JSON_FILE" (when not already present).
    * If INDEX is set, it adds: --index "$INDEX" (when not already present).
    * If MFA is set, it adds: --mfa "$MFA" (when not already present).
    * EXTRA_ARGS is appended verbatim at the end (can hold global flags).
EOF
}

show_cmd() {
  echo "JSON_FILE = ${JSON_FILE:-<unset>}"
  echo "INDEX     = ${INDEX:-<unset>}"
  echo "MFA       = ${MFA:-<unset>}"
  echo "EXTRA_ARGS= ${EXTRA_ARGS:-<unset>}"
}

setvar_cmd() {
  local name="${1:-}" value="${2:-}"
  if [[ -z "${name}" || -z "${value}" ]]; then
    err "Usage: setvar NAME VALUE"
    return 1
  fi
  case "$name" in
    JSON_FILE|INDEX|MFA|EXTRA_ARGS)
      printf -v "$name" "%s" "$value"
      ok "$name set to '$value'"
      ;;
    *)
      err "Unknown variable '$name'. Allowed: JSON_FILE, INDEX, MFA, EXTRA_ARGS"
      return 1
      ;;
  esac
}

peek_index_cmd() {
  local idx="${1:-}"
  if [[ -z "$idx" ]]; then
    err "Usage: peek-index <N>"
    return 1
  fi
  if [[ -z "${JSON_FILE:-}" ]]; then
    err "JSON_FILE is not set. Use: setvar JSON_FILE path/to/file.json"
    return 1
  fi
  if [[ ! -f "$JSON_FILE" ]]; then
    err "JSON_FILE not found: $JSON_FILE"
    return 1
  fi
  if ! _exists jq; then
    err "'jq' is required for peek-index. Install and retry."
    return 1
  fi
  jq -r ".[$idx]" "$JSON_FILE"
}

# Append convenience vars unless already explicitly provided.
augment_args() {
  local -a args=("$@")
  local joined=" $* "
  if [[ -n "${JSON_FILE:-}" && "$joined" != *" --json "* && "$joined" != *" --json="* ]]; then
    args+=("--json" "$JSON_FILE")
  fi
  if [[ -n "${INDEX:-}" && "$joined" != *" --index "* && "$joined" != *" --index="* ]]; then
    args+=("--index" "$INDEX")
  fi
  if [[ -n "${MFA:-}" && "$joined" != *" --mfa "* && "$joined" != *" --mfa="* ]]; then
    args+=("--mfa" "$MFA")
  fi
  if [[ -n "${EXTRA_ARGS:-}" ]]; then
    # shellcheck disable=SC2206
    extra_arr=($EXTRA_ARGS)
    args+=("${extra_arr[@]}")
  fi
  printf '%s\0' "${args[@]}"
}

dispatch_cmd() {
  local cmd="$1"; shift || true
  local script="${CMD_TO_SCRIPT[$cmd]:-}"
  if [[ -z "$script" ]]; then
    err "Unknown command: $cmd. Type 'help'."
    return 1
  fi

  # Augment args with convenience vars
  mapfile -d '' aug < <(augment_args "$@")
  # Run the script with augmented args
  run_script "$script" "${aug[@]}"
}

# ---------- REPL ----------
main_loop() {
  info "Device Registry Interactive Shell"
  info "Scripts directory: $SCRIPT_DIR"
  info "Type 'help' to see available commands."
  touch -- "$HISTFILE" 2>/dev/null || true
  # Enable history appending
  shopt -s histappend || true
  # Use readline if available
  while true; do
    # Save history each loop
    history -a || true

    # Prompt
    read -e -r -p "devreg> " line || { echo; break; }
    # Skip empty
    [[ -z "$line" ]] && continue
    # Save line to history
    history -s -- "$line" || true

    # Parse command into array (respect quotes)
    eval "args=( $line )"
    cmd="${args[0]}"
    unset 'args[0]' || true

    case "$cmd" in
      help|\?)
        help_cmd
        ;;
      show)
        show_cmd
        ;;
      setvar)
        setvar_cmd "${args[@]}"
        ;;
      peek-index)
        peek_index_cmd "${args[@]}"
        ;;
      exit|quit)
        break
        ;;
      history)
        builtin history
        ;;
      auth|register|provision|events|get-state)
        dispatch_cmd "$cmd" "${args[@]}"
        ;;
      *)
        err "Unrecognized command: $cmd"
        ;;
    esac
  done
  ok "Goodbye."
}

main_loop
