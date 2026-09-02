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
