load test_helper

setup() {
    if ! command -v age >/dev/null 2>&1 || ! command -v age-keygen >/dev/null 2>&1; then
        skip "age/age-keygen not installed"
    fi
    zfleak_test_setup
    export ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_CONFIG_DIR/vault"
}

teardown() { zfleak_test_teardown; }

@test "migrate requires a --to-backend flag" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    run "$ZFLEAK_BIN" migrate demo
    [ "$status" -eq 1 ]
    [[ "$output" == *"--to-backend"* ]]
}

@test "migrate rejects an unsupported backend" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    run "$ZFLEAK_BIN" migrate demo --to-backend invalid
    [ "$status" -eq 1 ]
    [[ "$output" == *"keychain"* ]]
}

@test "migrate errors for an unknown project" {
    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" "$ZFLEAK_BIN" migrate ghost --to-backend file
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "migrate rejects an invalid project name" {
    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" "$ZFLEAK_BIN" migrate "foo/bar" --to-backend file
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid project name"* ]]
}

@test "migrate converts export lines to secret references and stores values in the backend" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    printf 'export DB_PASSWORD=super-secret\n' >> "$ZFLEAK_CONFIG_DIR/demo.zsh"

    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" "$ZFLEAK_BIN" migrate demo --to-backend file
    [ "$status" -eq 0 ]

    run cat "$ZFLEAK_CONFIG_DIR/demo.zsh"
    [[ "$output" == *"# zfleak:secret DB_PASSWORD=demo/DB_PASSWORD"* ]]
    [[ "$output" != *"export DB_PASSWORD=super-secret"* ]]

    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" ZFLEAK_VAULT_BACKEND=file bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get demo/DB_PASSWORD
    "
    [ "$output" = "super-secret" ]
}

@test "migrate leaves non-secret lines untouched" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    printf 'export DB_PASSWORD=super-secret\n' >> "$ZFLEAK_CONFIG_DIR/demo.zsh"
    env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" "$ZFLEAK_BIN" migrate demo --to-backend file >/dev/null

    run cat "$ZFLEAK_CONFIG_DIR/demo.zsh"
    [[ "$output" == *"demo - Development Environment"* ]]
}

@test "migrated project still resolves the secret when loaded via use-project" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    printf 'export DB_PASSWORD=super-secret\n' >> "$ZFLEAK_CONFIG_DIR/demo.zsh"
    env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" "$ZFLEAK_BIN" migrate demo --to-backend file >/dev/null

    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" ZFLEAK_VAULT_BACKEND=file bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.bash'
        use-project demo
        echo \"DB=[\$DB_PASSWORD]\"
    "
    [[ "$output" == *"DB=[super-secret]"* ]]
}

@test "migrate preserves the sensitive-project marker" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    printf 'export ZFLEAK_SENSITIVE=true\n' >> "$ZFLEAK_CONFIG_DIR/demo.zsh"

    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_VAULT_FILE_DIR" \
        "$ZFLEAK_BIN" migrate demo --to-backend file
    [ "$status" -eq 0 ]

    run grep -q '^export ZFLEAK_SENSITIVE=true$' "$ZFLEAK_CONFIG_DIR/demo.zsh"
    [ "$status" -eq 0 ]
}
