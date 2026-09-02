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

# ----------------------------------------------------------------------------
# Task 2: directory permissions (config dir + archive dir owner-only)
# ----------------------------------------------------------------------------

@test "install.sh creates the config dir and archive dir as 700" {
    local fake_home
    fake_home="$(mktemp -d)"
    HOME="$fake_home" SHELL=/bin/bash bash -c "echo y | bash '$ZFLEAK_REPO_ROOT/install.sh'" >/dev/null
    [ "$(zfleak_perms "$fake_home/.zfleak.d")" = "700" ]
    [ "$(zfleak_perms "$fake_home/.zfleak.d/.archive")" = "700" ]
    rm -rf "$fake_home"
}

@test "archive creates the archive dir as 700" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    "$ZFLEAK_BIN" archive demo >/dev/null
    [ "$(zfleak_perms "$ZFLEAK_CONFIG_DIR/.archive")" = "700" ]
}

# ----------------------------------------------------------------------------
# Task 3: file permissions (config file, projects.conf, common.zsh owner-only)
# ----------------------------------------------------------------------------

@test "new-project creates the config file as 600" {
    "$ZFLEAK_BIN" new-project demo >/dev/null
    [ "$(zfleak_perms "$ZFLEAK_CONFIG_DIR/demo.zsh")" = "600" ]
}

@test "new-project with a path creates projects.conf as 600" {
    "$ZFLEAK_BIN" new-project demo "$HOME/projects/demo" >/dev/null
    [ "$(zfleak_perms "$ZFLEAK_CONFIG_DIR/projects.conf")" = "600" ]
}

@test "install.sh creates common.zsh and projects.conf as 600" {
    local fake_home
    fake_home="$(mktemp -d)"
    HOME="$fake_home" SHELL=/bin/bash bash -c "echo y | bash '$ZFLEAK_REPO_ROOT/install.sh'" >/dev/null
    [ "$(zfleak_perms "$fake_home/.zfleak.d/common.zsh")" = "600" ]
    [ "$(zfleak_perms "$fake_home/.zfleak.d/projects.conf")" = "600" ]
    rm -rf "$fake_home"
}
