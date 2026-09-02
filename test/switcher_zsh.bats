load test_helper

setup() {
    zfleak_test_setup
    mkdir -p "$ZFLEAK_CONFIG_DIR/.archive"
    cat > "$ZFLEAK_CONFIG_DIR/demo.zsh" <<'EOF'
export DEMO_VAR=hello
export DEMO_OTHER=world
EOF
}
teardown() { zfleak_test_teardown; }

@test "(zsh) use-project sources exported vars and sets ACTIVE_PROJECT" {
    run zsh -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.zsh'
        use-project demo
        echo \"ACTIVE=\$ACTIVE_PROJECT\"
        echo \"VAR=\$DEMO_VAR\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ACTIVE=demo"* ]] || false
    [[ "$output" == *"VAR=hello"* ]]
}

@test "(zsh) use-project reports an error for an unknown project" {
    run zsh -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.zsh'
        use-project ghost
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "(zsh) clear-project unsets vars loaded by use-project" {
    run zsh -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.zsh'
        use-project demo >/dev/null
        clear-project >/dev/null
        echo \"VAR=[\$DEMO_VAR]\"
        echo \"ACTIVE=[\$ACTIVE_PROJECT]\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"VAR=[]"* ]] || false
    [[ "$output" == *"ACTIVE=[]"* ]]
}

@test "(zsh) list-projects lists the demo project" {
    run zsh -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.zsh'
        list-projects
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"demo"* ]]
}

@test "(zsh) _auto_detect_project loads a project whose registered path matches PWD" {
    echo "demo:$ZFLEAK_CONFIG_DIR/workdir" > "$ZFLEAK_CONFIG_DIR/projects.conf"
    mkdir -p "$ZFLEAK_CONFIG_DIR/workdir"
    run zsh -c "
        source '$ZFLEAK_REPO_ROOT/lib/switcher.zsh'
        cd '$ZFLEAK_CONFIG_DIR/workdir'
        _auto_detect_project
        echo \"ACTIVE=\$ACTIVE_PROJECT\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"ACTIVE=demo"* ]]
}
