load test_helper

# ----------------------------------------------------------------------------
# Task 1: _vault_get/_vault_set/_vault_delete backend dispatch contract
# ----------------------------------------------------------------------------

@test "_vault_get dispatches to the selected backend's _vault_get_<name>" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_mock() { echo \"got:\$1\"; }
        ZFLEAK_VAULT_BACKEND=mock _vault_get somekey
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "got:somekey" ]]
}

@test "_vault_set dispatches to the selected backend's _vault_set_<name>" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set_mock() { echo \"set:\$1=\$2\"; }
        ZFLEAK_VAULT_BACKEND=mock _vault_set somekey somevalue
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "set:somekey=somevalue" ]]
}

@test "_vault_delete dispatches to the selected backend's _vault_delete_<name>" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_delete_mock() { echo \"deleted:\$1\"; }
        ZFLEAK_VAULT_BACKEND=mock _vault_delete somekey
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "deleted:somekey" ]]
}

@test "dispatch errors clearly when the selected backend has no implementation" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        ZFLEAK_VAULT_BACKEND=nope _vault_get somekey
    "
    [ "$status" -ne 0 ]
    [[ "$output" == *"nope"* ]]
}

@test "(zsh) _vault_get dispatches to the selected backend's _vault_get_<name>" {
    run zsh -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_get_mock() { echo \"got:\$1\"; }
        ZFLEAK_VAULT_BACKEND=mock _vault_get somekey
    "
    [ "$status" -eq 0 ]
    [[ "$output" == "got:somekey" ]]
}

# ----------------------------------------------------------------------------
# Task 2: --backend flag / ZFLEAK_VAULT_BACKEND with OS auto-detect default
# ----------------------------------------------------------------------------

@test "_zfleak_default_vault_backend picks keychain on Darwin" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        uname() { echo Darwin; }
        _zfleak_default_vault_backend
    "
    [ "$output" = "keychain" ]
}

@test "_zfleak_default_vault_backend picks pass when installed and not on Darwin" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        uname() { echo Linux; }
        pass() { :; }
        _zfleak_default_vault_backend
    "
    [ "$output" = "pass" ]
}

@test "_zfleak_default_vault_backend falls back to file otherwise" {
    # Sandbox PATH so a real `pass` binary on the dev/CI machine (e.g.
    # installed via brew) can't leak into this "pass not available" case.
    local empty_path
    empty_path="$(mktemp -d)"
    run bash -c "
        PATH='$empty_path'
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        uname() { echo Linux; }
        _zfleak_default_vault_backend
    "
    rm -rf "$empty_path"
    [ "$output" = "file" ]
}

setup() { zfleak_test_setup; }
teardown() { zfleak_test_teardown; }

@test "vault-backend reports the auto-detected default when unset" {
    run "$ZFLEAK_BIN" vault-backend
    [ "$status" -eq 0 ]
    [[ -n "$output" ]]
}

@test "ZFLEAK_VAULT_BACKEND overrides the auto-detected default" {
    run bash -c "ZFLEAK_VAULT_BACKEND=pass '$ZFLEAK_BIN' vault-backend"
    [ "$status" -eq 0 ]
    [[ "$output" == *"pass"* ]]
}

@test "--backend overrides the auto-detected default" {
    run "$ZFLEAK_BIN" --backend pass vault-backend
    [ "$status" -eq 0 ]
    [[ "$output" == *"pass"* ]]
}

@test "--backend still lets the requested subcommand run normally" {
    run "$ZFLEAK_BIN" --backend pass new-project demo
    [ "$status" -eq 0 ]
    [ -f "$ZFLEAK_CONFIG_DIR/demo.zsh" ]
}
