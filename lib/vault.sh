# ============================================================================
# zfleak vault backend dispatch
# ============================================================================
# Backends implement _vault_get_<name>, _vault_set_<name>, and
# _vault_delete_<name>. Which backend handles a call is chosen by
# ZFLEAK_VAULT_BACKEND (or the --backend flag in bin/zfleak, which sets
# that same variable), falling back to an OS-aware default when unset.
#
# Real backend implementations (macOS Keychain, pass, encrypted file)
# land in a later phase; this file only defines the dispatch contract.
# ============================================================================

_zfleak_default_vault_backend() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "keychain"
    elif command -v pass >/dev/null 2>&1; then
        echo "pass"
    else
        echo "file"
    fi
}

_zfleak_vault_dispatch() {
    local op=$1
    local key=$2
    local value=$3
    local backend="${ZFLEAK_VAULT_BACKEND:-$(_zfleak_default_vault_backend)}"
    local fn="_vault_${op}_${backend}"
    
    if ! command -v "$fn" >/dev/null 2>&1; then
        echo "Unknown vault backend '$backend' (no $fn implementation)" >&2
        return 1
    fi
    
    case "$op" in
        get) "$fn" "$key" ;;
        set) "$fn" "$key" "$value" ;;
        delete) "$fn" "$key" ;;
    esac
}

_vault_get() {
    _zfleak_vault_dispatch get "$1"
}

_vault_set() {
    _zfleak_vault_dispatch set "$1" "$2"
}

_vault_delete() {
    _zfleak_vault_dispatch delete "$1"
}

# ============================================================================
# macOS Keychain backend
# ============================================================================
# Each vault key becomes a generic-password item named "zfleak-<key>"
# under the current user's account. Targets ZFLEAK_KEYCHAIN directly
# when set (used by tests, and by anyone who wants a non-default
# keychain); otherwise falls back to the user's default keychain.

_vault_get_keychain() {
    local key=$1
    local -a args
    args=(-a "$USER" -s "zfleak-$key" -w)
    [[ -n "$ZFLEAK_KEYCHAIN" ]] && args+=("$ZFLEAK_KEYCHAIN")
    security find-generic-password "${args[@]}" 2>/dev/null
}

_vault_set_keychain() {
    local key=$1
    local value=$2
    local -a args
    args=(-a "$USER" -s "zfleak-$key" -w "$value" -U)
    [[ -n "$ZFLEAK_KEYCHAIN" ]] && args+=("$ZFLEAK_KEYCHAIN")
    security add-generic-password "${args[@]}" >/dev/null 2>&1
}

_vault_delete_keychain() {
    local key=$1
    local -a args
    args=(-a "$USER" -s "zfleak-$key")
    [[ -n "$ZFLEAK_KEYCHAIN" ]] && args+=("$ZFLEAK_KEYCHAIN")
    security delete-generic-password "${args[@]}" >/dev/null 2>&1
}

# ============================================================================
# pass (passwordstore.org) backend
# ============================================================================
# Each vault key becomes a pass entry at "zfleak/<key>", value stored as
# the first line of the entry (pass's usual convention for the "main"
# secret, with room for metadata on following lines if ever needed).

_vault_get_pass() {
    local key=$1
    local entry
    entry="$(pass show "zfleak/$key" 2>/dev/null)" || return 1
    printf '%s\n' "$entry" | head -n1
}

_vault_set_pass() {
    local key=$1
    local value=$2
    printf '%s\n' "$value" | pass insert -m -f "zfleak/$key" >/dev/null 2>&1
}

_vault_delete_pass() {
    local key=$1
    pass rm -f "zfleak/$key" >/dev/null 2>&1
}

# ============================================================================
# Encrypted file backend (universal fallback)
# ============================================================================
# Each vault key is stored as its own age-encrypted file. A local age
# identity is generated on first use under ZFLEAK_VAULT_FILE_DIR (default
# ~/.zfleak.d/vault), never a shared/master passphrase.

_zfleak_vault_file_dir() {
    echo "${ZFLEAK_VAULT_FILE_DIR:-${ZFLEAK_CONFIG_DIR:-$HOME/.zfleak.d}/vault}"
}

_zfleak_vault_file_identity() {
    echo "$(_zfleak_vault_file_dir)/identity.txt"
}

_zfleak_vault_file_path() {
    local key=$1
    echo "$(_zfleak_vault_file_dir)/$(echo "$key" | tr '/' '_').age"
}

_zfleak_vault_file_ensure_identity() {
    local dir identity
    dir="$(_zfleak_vault_file_dir)"
    identity="$(_zfleak_vault_file_identity)"
    mkdir -p "$dir"
    chmod 700 "$dir"
    if [[ ! -f "$identity" ]]; then
        age-keygen -o "$identity" >/dev/null 2>&1
        chmod 600 "$identity"
    fi
}

_vault_get_file() {
    local key=$1
    local identity file
    identity="$(_zfleak_vault_file_identity)"
    file="$(_zfleak_vault_file_path "$key")"
    [[ -f "$identity" && -f "$file" ]] || return 1
    age -d -i "$identity" "$file" 2>/dev/null
}

_vault_set_file() {
    local key=$1
    local value=$2
    local identity file pubkey
    _zfleak_vault_file_ensure_identity
    identity="$(_zfleak_vault_file_identity)"
    file="$(_zfleak_vault_file_path "$key")"
    pubkey="$(age-keygen -y "$identity" 2>/dev/null)" || return 1
    printf '%s' "$value" | age -r "$pubkey" -o "$file" 2>/dev/null || return 1
    chmod 600 "$file"
}

_vault_delete_file() {
    local key=$1
    rm -f "$(_zfleak_vault_file_path "$key")"
}

