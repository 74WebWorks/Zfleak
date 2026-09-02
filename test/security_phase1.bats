load test_helper

setup() { zfleak_test_setup; }
teardown() { zfleak_test_teardown; }

# ----------------------------------------------------------------------------
# Task 1: project_name validation
# ----------------------------------------------------------------------------

@test "new-project rejects a path-traversal project name" {
    run "$ZFLEAK_BIN" new-project "../evil"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid project name"* ]]
}

@test "new-project rejects a project name with a slash" {
    run "$ZFLEAK_BIN" new-project "foo/bar"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid project name"* ]]
}

@test "new-project rejects a project name with shell metacharacters" {
    run "$ZFLEAK_BIN" new-project 'foo;rm -rf ~'
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid project name"* ]]
}

@test "new-project accepts letters, numbers, dash, and underscore" {
    run "$ZFLEAK_BIN" new-project "Demo-App_2"
    [ "$status" -eq 0 ]
    [ -f "$ZFLEAK_CONFIG_DIR/Demo-App_2.zsh" ]
}

@test "register-path rejects an invalid project name" {
    run "$ZFLEAK_BIN" register-path "../evil" "$HOME/x"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid project name"* ]]
}

@test "edit rejects an invalid project name" {
    run "$ZFLEAK_BIN" edit "foo/bar"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid project name"* ]]
}

@test "show rejects an invalid project name" {
    run "$ZFLEAK_BIN" show "foo/bar"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid project name"* ]]
}

@test "archive rejects an invalid project name" {
    run "$ZFLEAK_BIN" archive "foo/bar"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid project name"* ]]
}

@test "restore rejects an invalid project name" {
    run "$ZFLEAK_BIN" restore "foo/bar"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid project name"* ]]
}
