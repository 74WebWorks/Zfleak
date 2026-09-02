load test_helper

setup() {
    ZFLEAK_FAKE_HOME="$(mktemp -d)"
}
teardown() {
    [[ -n "$ZFLEAK_FAKE_HOME" && -d "$ZFLEAK_FAKE_HOME" ]] && rm -rf "$ZFLEAK_FAKE_HOME"
}

@test "install.sh sets up bin, config dir, and rc file under a fake HOME" {
    run bash -c "
        export HOME='$ZFLEAK_FAKE_HOME'
        export SHELL=/bin/bash
        echo y | bash '$ZFLEAK_REPO_ROOT/install.sh'
    "
    [ "$status" -eq 0 ]
    [ -x "$ZFLEAK_FAKE_HOME/.local/bin/zfleak" ]
    [ -f "$ZFLEAK_FAKE_HOME/.zfleak.d/switcher.bash" ]
    [ -f "$ZFLEAK_FAKE_HOME/.zfleak.d/switcher.zsh" ]
    [ -f "$ZFLEAK_FAKE_HOME/.zfleak.d/projects.conf" ]
    [ -f "$ZFLEAK_FAKE_HOME/.zfleak.d/common.zsh" ]
    grep -q "zfleak" "$ZFLEAK_FAKE_HOME/.bashrc"
}

@test "install.sh declining the prompt does not install anything" {
    run bash -c "
        export HOME='$ZFLEAK_FAKE_HOME'
        export SHELL=/bin/bash
        echo n | bash '$ZFLEAK_REPO_ROOT/install.sh'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"cancelled"* ]]
    [ ! -f "$ZFLEAK_FAKE_HOME/.local/bin/zfleak" ]
}
