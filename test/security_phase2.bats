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
