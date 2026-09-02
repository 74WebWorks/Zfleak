load test_helper

setup() {
    zfleak_test_setup
    mkdir -p "$ZFLEAK_CONFIG_DIR/.archive"
    cat > "$ZFLEAK_CONFIG_DIR/demo.zsh" <<'EOF'
export DEMO_VAR=hello
EOF
    cat > "$ZFLEAK_CONFIG_DIR/prod.zsh" <<'EOF'
export ZFLEAK_SENSITIVE=true
export PROD_DB_PASSWORD=super-secret
EOF
}
teardown() { zfleak_test_teardown; }

# ----------------------------------------------------------------------------
# Task 1: ZFLEAK_SENSITIVE marker + confirmation gate
# ----------------------------------------------------------------------------

@test "(bash) use-project loads a non-sensitive project without prompting" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.bash'
        use-project demo
        echo \"ACTIVE=[\$ACTIVE_PROJECT]\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ACTIVE=[demo]"* ]]
}

@test "(bash) use-project refuses to load a sensitive project entirely" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.bash'
        use-project prod
        st=\$?
        echo \"ACTIVE=[\$ACTIVE_PROJECT]\"
        exit \$st
    "
    [ "$status" -ne 0 ]
    [[ "$output" == *"ACTIVE=[]"* ]] || false
    [[ "$output" == *"zfleak run"* ]]
}

@test "(bash) ZFLEAK_ASSUME_YES=1 does not bypass the sensitive-project block" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.bash'
        ZFLEAK_ASSUME_YES=1 use-project prod
        st=\$?
        echo \"ACTIVE=[\$ACTIVE_PROJECT]\"
        exit \$st
    "
    [ "$status" -ne 0 ]
    [[ "$output" == *"ACTIVE=[]"* ]]
}

@test "(zsh) use-project refuses to load a sensitive project entirely" {
    run zsh -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.zsh'
        use-project prod
        st=\$?
        echo \"ACTIVE=[\$ACTIVE_PROJECT]\"
        exit \$st
    "
    [ "$status" -ne 0 ]
    [[ "$output" == *"ACTIVE=[]"* ]] || false
    [[ "$output" == *"zfleak run"* ]]
}

# ----------------------------------------------------------------------------
# Task 2: `zfleak set-passphrase` + password-gate `show --reveal`
# ----------------------------------------------------------------------------

@test "show --reveal on a non-sensitive project is not gated" {
    run "$ZFLEAK_BIN" show demo --reveal
    [ "$status" -eq 0 ]
    [[ "$output" == *"DEMO_VAR=hello"* ]]
}

@test "show --reveal on a sensitive project without a passphrase set errors" {
    run "$ZFLEAK_BIN" show prod --reveal
    [ "$status" -eq 1 ]
    [[ "$output" == *"set-passphrase"* ]]
}

@test "set-passphrase requires the confirmation to match" {
    run bash -c "printf 'hunter2\\nwrong\\n' | '$ZFLEAK_BIN' set-passphrase"
    [ "$status" -eq 1 ]
    [[ "$output" == *"did not match"* ]] || false
    [ ! -f "$ZFLEAK_CONFIG_DIR/.reveal_passphrase" ]
}

@test "set-passphrase stores a 600 passphrase file" {
    run bash -c "printf 'hunter2\\nhunter2\\n' | '$ZFLEAK_BIN' set-passphrase"
    [ "$status" -eq 0 ]
    [ "$(zfleak_perms "$ZFLEAK_CONFIG_DIR/.reveal_passphrase")" = "600" ]
}

@test "show --reveal on a sensitive project succeeds with the correct passphrase" {
    bash -c "printf 'hunter2\\nhunter2\\n' | '$ZFLEAK_BIN' set-passphrase" >/dev/null
    run bash -c "printf 'hunter2\\n' | '$ZFLEAK_BIN' show prod --reveal"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PROD_DB_PASSWORD=super-secret"* ]]
}

@test "show --reveal on a sensitive project fails with the wrong passphrase" {
    bash -c "printf 'hunter2\\nhunter2\\n' | '$ZFLEAK_BIN' set-passphrase" >/dev/null
    run bash -c "printf 'wrong\\n' | '$ZFLEAK_BIN' show prod --reveal"
    [ "$status" -eq 1 ]
    [[ "$output" != *"super-secret"* ]]
}

# ----------------------------------------------------------------------------
# Task 3: lockout after 3 failed attempts + audit log + OS-auth unlock
# ----------------------------------------------------------------------------

@test "3 failed reveal attempts trigger a lockout" {
    bash -c "printf 'hunter2\\nhunter2\\n' | '$ZFLEAK_BIN' set-passphrase" >/dev/null
    bash -c "printf 'wrong\\n' | '$ZFLEAK_BIN' show prod --reveal" >/dev/null || true
    bash -c "printf 'wrong\\n' | '$ZFLEAK_BIN' show prod --reveal" >/dev/null || true
    bash -c "printf 'wrong\\n' | '$ZFLEAK_BIN' show prod --reveal" >/dev/null || true
    [ -f "$ZFLEAK_CONFIG_DIR/.locked" ]

    # even the correct passphrase is now refused
    run bash -c "printf 'hunter2\\n' | '$ZFLEAK_BIN' show prod --reveal"
    [ "$status" -eq 1 ]
    [[ "$output" == *"locked"* ]] || false
    [[ "$output" != *"super-secret"* ]]
}

@test "lockout and failed attempts are recorded in the audit log" {
    bash -c "printf 'hunter2\\nhunter2\\n' | '$ZFLEAK_BIN' set-passphrase" >/dev/null
    bash -c "printf 'wrong\\n' | '$ZFLEAK_BIN' show prod --reveal" >/dev/null || true
    bash -c "printf 'wrong\\n' | '$ZFLEAK_BIN' show prod --reveal" >/dev/null || true
    bash -c "printf 'wrong\\n' | '$ZFLEAK_BIN' show prod --reveal" >/dev/null || true
    [ -f "$ZFLEAK_CONFIG_DIR/.audit.log" ]
    [ "$(grep -c 'failed_attempt' "$ZFLEAK_CONFIG_DIR/.audit.log")" -eq 3 ]
    [ "$(grep -c 'lockout' "$ZFLEAK_CONFIG_DIR/.audit.log")" -eq 1 ]
    grep -q "prod" "$ZFLEAK_CONFIG_DIR/.audit.log"
}

@test "unlock with failed OS auth does not clear the lockout" {
    bash -c "printf 'hunter2\\nhunter2\\n' | '$ZFLEAK_BIN' set-passphrase" >/dev/null
    for _ in 1 2 3; do
        bash -c "printf 'wrong\\n' | '$ZFLEAK_BIN' show prod --reveal" >/dev/null || true
    done
    run bash -c "printf 'anything\\n' | ZFLEAK_TEST_AUTH_OK=0 '$ZFLEAK_BIN' unlock"
    [ -f "$ZFLEAK_CONFIG_DIR/.locked" ]
}

@test "unlock with successful OS auth clears the lockout" {
    bash -c "printf 'hunter2\\nhunter2\\n' | '$ZFLEAK_BIN' set-passphrase" >/dev/null
    for _ in 1 2 3; do
        bash -c "printf 'wrong\\n' | '$ZFLEAK_BIN' show prod --reveal" >/dev/null || true
    done
    [ -f "$ZFLEAK_CONFIG_DIR/.locked" ]
    run bash -c "printf 'anything\\n' | ZFLEAK_TEST_AUTH_OK=1 '$ZFLEAK_BIN' unlock"
    [ "$status" -eq 0 ]
    [ ! -f "$ZFLEAK_CONFIG_DIR/.locked" ]

    run bash -c "printf 'hunter2\\n' | '$ZFLEAK_BIN' show prod --reveal"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PROD_DB_PASSWORD=super-secret"* ]]
}

@test "a successful reveal resets the failed-attempt counter" {
    bash -c "printf 'hunter2\\nhunter2\\n' | '$ZFLEAK_BIN' set-passphrase" >/dev/null
    bash -c "printf 'wrong\\n' | '$ZFLEAK_BIN' show prod --reveal" >/dev/null || true
    bash -c "printf 'wrong\\n' | '$ZFLEAK_BIN' show prod --reveal" >/dev/null || true
    bash -c "printf 'hunter2\\n' | '$ZFLEAK_BIN' show prod --reveal" >/dev/null
    bash -c "printf 'wrong\\n' | '$ZFLEAK_BIN' show prod --reveal" >/dev/null || true
    bash -c "printf 'wrong\\n' | '$ZFLEAK_BIN' show prod --reveal" >/dev/null || true
    [ ! -f "$ZFLEAK_CONFIG_DIR/.locked" ]
}
