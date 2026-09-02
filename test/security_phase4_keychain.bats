load test_helper

# ----------------------------------------------------------------------------
# Task 1: macOS Keychain backend (_vault_*_keychain)
# ----------------------------------------------------------------------------
# Runs against a disposable, throwaway keychain file (never the user's
# real login keychain), addressed directly via ZFLEAK_KEYCHAIN so it
# never needs to be added to anyone's keychain search list.

setup() {
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "macOS Keychain backend only runs on Darwin"
    fi
    zfleak_test_setup
    ZFLEAK_KEYCHAIN="$ZFLEAK_CONFIG_DIR/test.keychain-db"
    security create-keychain -p test-keychain-pass "$ZFLEAK_KEYCHAIN" >/dev/null
    security unlock-keychain -p test-keychain-pass "$ZFLEAK_KEYCHAIN" >/dev/null
}

teardown() {
    security delete-keychain "$ZFLEAK_KEYCHAIN" >/dev/null 2>&1 || true
    zfleak_test_teardown
}

@test "keychain backend: set then get round-trips a value" {
    run env ZFLEAK_KEYCHAIN="$ZFLEAK_KEYCHAIN" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set_keychain demo/db-password s3cr3t
    "
    [ "$status" -eq 0 ]

    run env ZFLEAK_KEYCHAIN="$ZFLEAK_KEYCHAIN" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_keychain demo/db-password
    "
    [ "$status" -eq 0 ]
    [ "$output" = "s3cr3t" ]
}

@test "keychain backend: setting again updates rather than duplicating" {
    env ZFLEAK_KEYCHAIN="$ZFLEAK_KEYCHAIN" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set_keychain demo/db-password first
        _vault_set_keychain demo/db-password second
    " >/dev/null

    run env ZFLEAK_KEYCHAIN="$ZFLEAK_KEYCHAIN" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_keychain demo/db-password
    "
    [ "$output" = "second" ]
}

@test "keychain backend: delete removes the item" {
    env ZFLEAK_KEYCHAIN="$ZFLEAK_KEYCHAIN" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set_keychain demo/db-password s3cr3t
    " >/dev/null

    run env ZFLEAK_KEYCHAIN="$ZFLEAK_KEYCHAIN" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_delete_keychain demo/db-password
    "
    [ "$status" -eq 0 ]

    run env ZFLEAK_KEYCHAIN="$ZFLEAK_KEYCHAIN" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_keychain demo/db-password
    "
    [ "$status" -ne 0 ]
}

@test "keychain backend: get on a missing key fails cleanly" {
    run env ZFLEAK_KEYCHAIN="$ZFLEAK_KEYCHAIN" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_keychain nope/nope
    "
    [ "$status" -ne 0 ]
}

@test "vault-backend keychain end-to-end via _vault_get/_vault_set dispatch" {
    run env ZFLEAK_KEYCHAIN="$ZFLEAK_KEYCHAIN" ZFLEAK_VAULT_BACKEND=keychain bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set demo/api-key abc123
        _vault_get demo/api-key
    "
    [ "$status" -eq 0 ]
    [ "$output" = "abc123" ]
}
