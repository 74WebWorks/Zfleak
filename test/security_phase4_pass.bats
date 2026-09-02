load test_helper

# ----------------------------------------------------------------------------
# Task 2: pass backend (_vault_*_pass)
# ----------------------------------------------------------------------------
# Runs against a disposable PASSWORD_STORE_DIR + a throwaway,
# no-passphrase GPG key generated fresh per test — never the
# developer's real password store or real GPG keyring.

setup() {
    if ! command -v pass >/dev/null 2>&1 || ! command -v gpg >/dev/null 2>&1; then
        skip "pass and/or gpg not installed"
    fi
    zfleak_test_setup
    export GNUPGHOME="$ZFLEAK_CONFIG_DIR/gnupg"
    mkdir -p "$GNUPGHOME"
    chmod 700 "$GNUPGHOME"
    cat > "$GNUPGHOME/genkey.batch" <<'BATCH'
%no-protection
Key-Type: RSA
Key-Length: 1024
Subkey-Type: RSA
Subkey-Length: 1024
Name-Real: zfleak test
Name-Email: test@zfleak.local
Expire-Date: 0
%commit
BATCH
    gpg --batch --gen-key "$GNUPGHOME/genkey.batch" >/dev/null 2>&1
    ZFLEAK_TEST_GPG_KEY_ID=$(gpg --list-keys --with-colons test@zfleak.local | awk -F: '/^pub/ {print $5; exit}')
    export PASSWORD_STORE_DIR="$ZFLEAK_CONFIG_DIR/password-store"
    pass init "$ZFLEAK_TEST_GPG_KEY_ID" >/dev/null 2>&1
}

teardown() {
    zfleak_test_teardown
}

@test "pass backend: set then get round-trips a value" {
    run env GNUPGHOME="$GNUPGHOME" PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set_pass demo/db-password s3cr3t
    "
    [ "$status" -eq 0 ]

    run env GNUPGHOME="$GNUPGHOME" PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_pass demo/db-password
    "
    [ "$status" -eq 0 ]
    [ "$output" = "s3cr3t" ]
}

@test "pass backend: setting again overwrites rather than erroring" {
    env GNUPGHOME="$GNUPGHOME" PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set_pass demo/db-password first
        _vault_set_pass demo/db-password second
    " >/dev/null

    run env GNUPGHOME="$GNUPGHOME" PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_pass demo/db-password
    "
    [ "$output" = "second" ]
}

@test "pass backend: delete removes the entry" {
    env GNUPGHOME="$GNUPGHOME" PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set_pass demo/db-password s3cr3t
    " >/dev/null

    run env GNUPGHOME="$GNUPGHOME" PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_delete_pass demo/db-password
    "
    [ "$status" -eq 0 ]

    run env GNUPGHOME="$GNUPGHOME" PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_pass demo/db-password
    "
    [ "$status" -ne 0 ]
}

@test "pass backend: get on a missing entry fails cleanly" {
    run env GNUPGHOME="$GNUPGHOME" PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_pass nope/nope
    "
    [ "$status" -ne 0 ]
}

@test "vault-backend pass end-to-end via _vault_get/_vault_set dispatch" {
    run env GNUPGHOME="$GNUPGHOME" PASSWORD_STORE_DIR="$PASSWORD_STORE_DIR" ZFLEAK_VAULT_BACKEND=pass bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set demo/api-key abc123
        _vault_get demo/api-key
    "
    [ "$status" -eq 0 ]
    [ "$output" = "abc123" ]
}
