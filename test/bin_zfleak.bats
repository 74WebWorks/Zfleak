load test_helper

setup() { zfleak_test_setup; }
teardown() { zfleak_test_teardown; }

@test "version prints a version string" {
    run "$ZFLEAK_BIN" version
    [ "$status" -eq 0 ]
    [[ "$output" == *"zfleak version"* ]]
}

@test "help prints usage when given no command" {
    run "$ZFLEAK_BIN"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "unknown command errors and shows help" {
    run "$ZFLEAK_BIN" bogus-command
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}

@test "new-project requires a name" {
    run "$ZFLEAK_BIN" new-project
    [ "$status" -eq 1 ]
    [[ "$output" == *"required"* ]]
}

@test "new-project creates a config file" {
    run "$ZFLEAK_BIN" new-project demo
    [ "$status" -eq 0 ]
    [ -f "$ZFLEAK_CONFIG_DIR/demo.zsh" ]
}

@test "new-project refuses to overwrite an existing project" {
    "$ZFLEAK_BIN" new-project demo
    run "$ZFLEAK_BIN" new-project demo
    [ "$status" -eq 1 ]
    [[ "$output" == *"already exists"* ]]
}

@test "new-project with a path registers it in projects.conf" {
    run "$ZFLEAK_BIN" new-project demo "$HOME/projects/demo"
    [ "$status" -eq 0 ]
    [ -f "$ZFLEAK_CONFIG_DIR/projects.conf" ]
    grep -q "^demo:$HOME/projects/demo$" "$ZFLEAK_CONFIG_DIR/projects.conf"
}

@test "register-path fails for a project that does not exist" {
    run "$ZFLEAK_BIN" register-path ghost "$HOME/projects/ghost"
    [ "$status" -eq 1 ]
    [[ "$output" == *"does not exist"* ]]
}

@test "register-path updates projects.conf for an existing project" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    run "$ZFLEAK_BIN" register-path demo "$HOME/projects/demo"
    [ "$status" -eq 0 ]
    grep -q "^demo:$HOME/projects/demo$" "$ZFLEAK_CONFIG_DIR/projects.conf"
}

@test "list shows active projects" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    run "$ZFLEAK_BIN" list
    [ "$status" -eq 0 ]
    [[ "$output" == *"demo"* ]]
}

@test "show requires a name" {
    run "$ZFLEAK_BIN" show
    [ "$status" -eq 1 ]
    [[ "$output" == *"required"* ]]
}

@test "show prints the config file contents" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    run "$ZFLEAK_BIN" show demo
    [ "$status" -eq 0 ]
    [[ "$output" == *"demo - Development Environment"* ]]
}

@test "show errors for an unknown project" {
    run "$ZFLEAK_BIN" show ghost
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "archive moves a project out of the active list" {
    "$ZFLEAK_BIN" new-project demo "$HOME/projects/demo" >/dev/null
    run "$ZFLEAK_BIN" archive demo
    [ "$status" -eq 0 ]
    [ ! -f "$ZFLEAK_CONFIG_DIR/demo.zsh" ]
    [ -f "$ZFLEAK_CONFIG_DIR/.archive/demo.zsh" ]
    ! grep -q "^demo:" "$ZFLEAK_CONFIG_DIR/projects.conf"
}

@test "archive errors for an unknown project" {
    run "$ZFLEAK_BIN" archive ghost
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "restore moves an archived project back to active" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    "$ZFLEAK_BIN" archive demo >/dev/null
    run "$ZFLEAK_BIN" restore demo
    [ "$status" -eq 0 ]
    [ -f "$ZFLEAK_CONFIG_DIR/demo.zsh" ]
    [ ! -f "$ZFLEAK_CONFIG_DIR/.archive/demo.zsh" ]
}

@test "restore errors for a project that is not archived" {
    run "$ZFLEAK_BIN" restore ghost
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}
