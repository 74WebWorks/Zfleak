load test_helper

# ----------------------------------------------------------------------------
# Task 3: encrypted file backend (_vault_*_file) — universal fallback
# ----------------------------------------------------------------------------
# Runs against a throwaway ZFLEAK_VAULT_FILE_DIR / age identity, never
# the real ~/.zfleak.d/vault.

setup() {
    if ! command -v age >/dev/null 2>&1 || ! command -v age-keygen >/dev/null 2>&1; then
        skip "age/age-keygen not installed"
    fi
    zfleak_test_setup
    export ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_CONFIG_DIR/vault"
}

teardown() { zfleak_test_teardown; }

@test "file backend: set then get round-trips a value" {
    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set_file demo/db-password s3cr3t
    "
    [ "$status" -eq 0 ]

    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_file demo/db-password
    "
    [ "$status" -eq 0 ]
    [ "$output" = "s3cr3t" ]
}

@test "file backend: the on-disk secret file is encrypted, not plaintext" {
    env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set_file demo/db-password s3cr3t
    " >/dev/null

    run bash -c "grep -RIl 's3cr3t' '$ZFLEAK_VAULT_FILE_DIR' || true"
    [ -z "$output" ]
}

@test "file backend: identity and vault files are created 600/700" {
    env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set_file demo/db-password s3cr3t
    " >/dev/null

    [ "$(zfleak_perms "$ZFLEAK_VAULT_FILE_DIR")" = "700" ]
    [ "$(zfleak_perms "$ZFLEAK_VAULT_FILE_DIR/identity.txt")" = "600" ]
    [ "$(zfleak_perms "$ZFLEAK_VAULT_FILE_DIR/demo_db-password.age")" = "600" ]
}

@test "file backend: setting again overwrites rather than erroring" {
    env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set_file demo/db-password first
        _vault_set_file demo/db-password second
    " >/dev/null

    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_file demo/db-password
    "
    [ "$output" = "second" ]
}

@test "file backend: delete removes the encrypted file" {
    env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set_file demo/db-password s3cr3t
    " >/dev/null

    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_delete_file demo/db-password
    "
    [ "$status" -eq 0 ]

    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_file demo/db-password
    "
    [ "$status" -ne 0 ]
}

@test "file backend: get on a missing key fails cleanly" {
    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_file nope/nope
    "
    [ "$status" -ne 0 ]
}

@test "vault-backend file end-to-end via _vault_get/_vault_set dispatch" {
    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" ZFLEAK_VAULT_BACKEND=file bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set demo/api-key abc123
        _vault_get demo/api-key
    "
    [ "$status" -eq 0 ]
    [ "$output" = "abc123" ]
}

# ----------------------------------------------------------------------------
# Task 3 (part 2): backend auto-detection priority order
# (keychain on Darwin -> pass if installed -> file always available)
# ----------------------------------------------------------------------------

@test "default backend priority: keychain wins over pass on Darwin" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        uname() { echo Darwin; }
        pass() { :; }
        _zfleak_default_vault_backend
    "
    [ "$output" = "keychain" ]
}

@test "default backend priority: pass wins over file when not on Darwin" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        uname() { echo Linux; }
        pass() { :; }
        _zfleak_default_vault_backend
    "
    [ "$output" = "pass" ]
}
