# ============================================================================
# Shared bats setup/teardown — isolates every test from the real
# ~/.zfleak.d and from the developer's shell rc files.
# ============================================================================

# Absolute path to the repo root, regardless of where bats is invoked from.
ZFLEAK_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZFLEAK_BIN="$ZFLEAK_REPO_ROOT/bin/zfleak"

zfleak_test_setup() {
    export ZFLEAK_CONFIG_DIR
    ZFLEAK_CONFIG_DIR="$(mktemp -d)"
}

zfleak_test_teardown() {
    [[ -n "$ZFLEAK_CONFIG_DIR" && -d "$ZFLEAK_CONFIG_DIR" ]] && rm -rf "$ZFLEAK_CONFIG_DIR"
}
