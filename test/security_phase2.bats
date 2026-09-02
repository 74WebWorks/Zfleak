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

@test "(bash) use-project on a sensitive project loads after typing yes" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.bash'
        use-project prod <<< 'yes'
        echo \"ACTIVE=[\$ACTIVE_PROJECT]\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ACTIVE=[prod]"* ]]
}

@test "(bash) use-project on a sensitive project aborts on anything but yes" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.bash'
        use-project prod <<< 'no'
        st=\$?
        echo \"ACTIVE=[\$ACTIVE_PROJECT]\"
        exit \$st
    "
    [ "$status" -ne 0 ]
    [[ "$output" == *"ACTIVE=[]"* ]]
}

@test "(bash) ZFLEAK_ASSUME_YES=1 skips the sensitive-project prompt" {
    run bash -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.bash'
        ZFLEAK_ASSUME_YES=1 use-project prod </dev/null
        echo \"ACTIVE=[\$ACTIVE_PROJECT]\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ACTIVE=[prod]"* ]]
}

@test "(zsh) use-project on a sensitive project loads after typing yes" {
    run zsh -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.zsh'
        use-project prod <<< 'yes'
        echo \"ACTIVE=[\$ACTIVE_PROJECT]\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ACTIVE=[prod]"* ]]
}

@test "(zsh) use-project on a sensitive project aborts on anything but yes" {
    run zsh -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.zsh'
        use-project prod <<< 'no'
        st=\$?
        echo \"ACTIVE=[\$ACTIVE_PROJECT]\"
        exit \$st
    "
    [ "$status" -ne 0 ]
    [[ "$output" == *"ACTIVE=[]"* ]]
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
    [[ "$output" == *"did not match"* ]]
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
