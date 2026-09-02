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
    # An `if` (not a bare `[[ ]] && rm` one-liner) so a "nothing to clean
    # up" case returns 0 instead of the false condition's exit status —
    # bats fails the test if teardown's own exit code is nonzero, even
    # for a skipped test (e.g. setup() called `skip` before ever setting
    # ZFLEAK_CONFIG_DIR).
    if [[ -n "$ZFLEAK_CONFIG_DIR" && -d "$ZFLEAK_CONFIG_DIR" ]]; then
        rm -rf "$ZFLEAK_CONFIG_DIR"
    fi
}

# Portable octal permission bits for a file/dir. GNU stat's -c is tried
# first: on macOS (BSD stat) -c isn't valid and fails cleanly, so this
# falls through to BSD's -f "%Lp". Trying BSD's "-f" first doesn't work
# the other way around: GNU stat's -f means "filesystem status" (a
# different, unrelated flag) and still exits 0 with garbage output, so
# the fallback would never trigger on Linux.
zfleak_perms() {
    stat -c "%a" "$1" 2>/dev/null || stat -f "%Lp" "$1"
}
