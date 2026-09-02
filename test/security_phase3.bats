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
