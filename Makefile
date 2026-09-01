.PHONY: test lint

test:
	bats test/

# Only fail on real errors; the zsh-only switcher.zsh uses syntax
# shellcheck's bash dialect can't parse (no zsh dialect exists), so it's
# checked at a lower bar and pre-existing warnings elsewhere aren't
# treated as blocking yet. SC2066/SC2296 are false positives here: they
# fire on zsh-only `${(@k)assoc}` expansion, which bash dialect can't
# understand but which is valid, intentional zsh syntax.
lint:
	shellcheck --severity=error -s bash bin/zfleak install.sh lib/switcher.bash
	shellcheck --severity=error -s bash --exclude=SC2066,SC2296 lib/switcher.zsh
