load test_helper

setup() { zfleak_test_setup; }
teardown() { zfleak_test_teardown; }

# ----------------------------------------------------------------------------
# Task 1: `zfleak run <project> -- <command...>` — child-process-only env
# ----------------------------------------------------------------------------

@test "run requires a project name" {
    run "$ZFLEAK_BIN" run
    [ "$status" -eq 1 ]
    [[ "$output" == *"required"* ]]
}

@test "run rejects an invalid project name" {
    run "$ZFLEAK_BIN" run "foo/bar" -- echo hi
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid project name"* ]]
}

@test "run errors for an unknown project" {
    run "$ZFLEAK_BIN" run ghost -- echo hi
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "run requires a -- separator before the command" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    run "$ZFLEAK_BIN" run demo echo hi
    [ "$status" -eq 1 ]
    [[ "$output" == *"--"* ]]
}

@test "run requires a command after --" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    run "$ZFLEAK_BIN" run demo --
    [ "$status" -eq 1 ]
    [[ "$output" == *"command"* ]]
}

@test "run exposes exported vars only to the child command" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    printf 'export DEMO_VAR=hello\n' >> "$ZFLEAK_CONFIG_DIR/demo.zsh"

    run bash -c "
        '$ZFLEAK_BIN' run demo -- printenv DEMO_VAR
        echo \"AFTER=[\${DEMO_VAR:-}]\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"hello"* ]] || false
    [[ "$output" == *"AFTER=[]"* ]]
}

@test "run resolves # zfleak:secret references for the child command only" {
    if ! command -v age >/dev/null 2>&1 || ! command -v age-keygen >/dev/null 2>&1; then
        skip "age/age-keygen not installed"
    fi
    "$ZFLEAK_BIN" new-project demo >/dev/null
    printf '# zfleak:secret DEMO_SECRET=demo/db-password\n' >> "$ZFLEAK_CONFIG_DIR/demo.zsh"
    ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_CONFIG_DIR/vault" ZFLEAK_VAULT_BACKEND=file bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/vault.sh'
        _vault_set demo/db-password s3cr3t
    "

    run env ZFLEAK_VAULT_FILE_DIR="$ZFLEAK_CONFIG_DIR/vault" ZFLEAK_VAULT_BACKEND=file bash -c "
        '$ZFLEAK_BIN' run demo -- printenv DEMO_SECRET
        echo \"AFTER=[\${DEMO_SECRET:-}]\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"s3cr3t"* ]] || false
    [[ "$output" == *"AFTER=[]"* ]]
}

@test "run reports a failure to resolve a secret reference clearly" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    printf '# zfleak:secret DEMO_SECRET=demo/db-password\n' >> "$ZFLEAK_CONFIG_DIR/demo.zsh"

    run "$ZFLEAK_BIN" run demo -- echo hi
    [ "$status" -eq 1 ]
}

@test "run's exit status matches the child command's exit status" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    run "$ZFLEAK_BIN" run demo -- bash -c "exit 42"
    [ "$status" -eq 42 ]
}
