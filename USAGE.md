# zfleak Usage Guide

This guide covers installation, project workflows, secret handling, vault
backends, the command reference, shell helpers, and troubleshooting.

## Contents

- [Quick Start](#quick-start)
- [CLI Syntax](#cli-syntax)
- [Files and Configuration](#files-and-configuration)
- [First Project](#first-project)
- [Secret Handling](#secret-handling)
- [Vault Backends](#vault-backends)
- [Command Reference](#command-reference)
- [Shell Helpers](#shell-helpers)
- [Troubleshooting](#troubleshooting)
- [Exit Status](#exit-status)

## Quick Start

### Prerequisites

- macOS or Linux
- Bash for the installer
- Zsh for the `zfleak` CLI, including when called from Bash
- `git` for clone-based or remote installation
- `curl` only for remote installation
- `age` and `age-keygen` when using the file backend
- An initialized `pass` store when using the pass backend

### Install from a clone

The installer asks for confirmation. This command answers `yes`
non-interactively:

```bash
git clone https://github.com/74WebWorks/Zfleak.git "$HOME/.zfleak-src"
cd "$HOME/.zfleak-src"
printf 'y\n' | ./install.sh
```

The installer places the CLI in `$HOME/.local/bin/zfleak`, installs
the shell libraries under `$HOME/.zfleak.d`, and adds the selected
library to your shell startup file.

Source the RC file named by the installer:

```bash
# Zsh
source "$HOME/.zshrc"

# Bash when the installer selected .bash_profile
# source "$HOME/.bash_profile"

# Bash otherwise
# source "$HOME/.bashrc"
```

Verify the installation:

```bash
zfleak --help
zfleak version
```

### Remote installation

Use process substitution so the installer's confirmation prompt remains
connected to the terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/74WebWorks/Zfleak/main/install.sh)
```

Do not use `curl ... | bash` with the current interactive installer.

## CLI Syntax

The general form is:

```text
zfleak [--backend <backend>] <command> [arguments...]
```

- `<value>` is required.
- `[value]` is optional.
- `<command...>` means one or more remaining command arguments.
- `--` ends `zfleak` parsing and passes the rest to a child
  command.
- Project names may contain only letters, numbers, hyphens, and underscores.

The global `--backend` option must appear before the command:

```bash
zfleak --backend file run demo -- printenv DB_PASSWORD
```

## Files and Configuration

The default configuration directory is `$HOME/.zfleak.d`. Set
`ZFLEAK_CONFIG_DIR` before sourcing the shell library if you use a
different location:

```bash
export ZFLEAK_CONFIG_DIR="$HOME/custom-zfleak"
source "$HOME/.zshrc"
```

Important paths:

- `$HOME/.local/bin/zfleak`: installed CLI
- `$HOME/.local/lib/vault.sh`: vault library used by the CLI
- `$HOME/.zfleak.d/<project-name>.zsh`: active project config
- `$HOME/.zfleak.d/.archive/<project-name>.zsh`: archived config
- `$HOME/.zfleak.d/projects.conf`: auto-detection mappings
- `$HOME/.zfleak.d/switcher.bash` and
  `switcher.zsh`: shell helpers
- `$HOME/.zfleak.d/vault.sh`: vault library used by shell helpers
- `$HOME/.zfleak.d/vault/identity.txt`: file-backend private identity
- `$HOME/.zfleak.d/vault/*.age`: encrypted file-backend values
- `$HOME/.zfleak.d/.reveal_passphrase`: reveal passphrase hash
- `$HOME/.zfleak.d/.lockout` and `.locked`: reveal lockout state
- `$HOME/.zfleak.d/.audit.log`: failed reveal and lockout events

Treat the configuration directory as private. Do not commit it as a whole:
it can contain plaintext values, authentication metadata, audit records, and
the file-backend identity. Back up the file-backend identity securely or its
encrypted values cannot be recovered.

## First Project

### Create and register a project

```bash
demo_dir="$HOME/work/zfleak-demo"
mkdir -p "$demo_dir"
zfleak new-project demo "$demo_dir"
```

`new-project` creates the config file and stores the path mapping. It
does not create or validate the directory.

### Add values

Open the project config:

```bash
zfleak edit demo
```

Simple values use exported assignments:

```bash
export APP_ENV=development
export DB_HOST=127.0.0.1
```

Project files are sourced as shell code by `use-project`. Only use
trusted config files. For portable behavior, keep them to simple exported
assignments and `zfleak` secret references.

### Load the project

Enter the registered directory:

```bash
cd "$HOME/work/zfleak-demo"
```

The shell hook attempts automatic detection. To load it explicitly:

```bash
use-project demo
```

Clear values loaded into the current shell:

```bash
clear-project
```

## Secret Handling

### Secret references

A reference maps an exported variable name to a vault key:

```bash
# zfleak:secret DB_PASSWORD=demo/DB_PASSWORD
```

The left side is the environment variable. The right side is the backend key.
The reference does not create the backend value; it must already exist.

There is no public `zfleak secret set` command. The supported public
way to populate a backend is `migrate`, which moves existing active
`export NAME=value` lines into a selected backend.

### Sensitive projects

Add this exact active line to a production or otherwise sensitive project:

```bash
export ZFLEAK_SENSITIVE=true
```

`use-project` refuses to load sensitive projects into the current
shell. Use a child process instead:

```bash
zfleak run demo -- your-application-command
```

This keeps project values out of the calling shell, but the child command and
its descendants can still read the environment.

### Masked output and reveal

By default, `show` masks every value on an exported assignment, not
only values marked as secret:

```bash
zfleak show demo
```

Reveal is opt-in:

```bash
zfleak show demo --reveal
```

For sensitive projects, this prompts for the reveal passphrase. The passphrase
is configured interactively:

```bash
zfleak set-passphrase
```

Three failed reveal attempts trigger a lockout. On macOS, clear it with OS
authentication:

```bash
zfleak unlock
```

Unlock support is currently unavailable on non-macOS platforms. A successful
reveal resets the failed-attempt counter.

## Vault Backends

When `ZFLEAK_VAULT_BACKEND` is unset, `zfleak` selects:

1. `keychain` on macOS
2. `pass` on other Unix-like systems when `pass` is installed
3. `file` otherwise

Check the selected name:

```bash
zfleak vault-backend
```

This checks selection, not whether the backend is ready to store or retrieve a
value.

### Keychain

The keychain backend uses the current macOS user's Keychain and the built-in
`security` command. It is the default on macOS and needs no separate setup.
Verify the command before troubleshooting zfleak:

```bash
command -v security
zfleak --backend keychain vault-backend
```

It is not available on non-macOS platforms.

### pass

The pass backend stores values below `zfleak/<vault-key>`. Install `pass` and
GnuPG with your OS package manager. If you do not already have a GPG key,
create one with `gpg --full-generate-key`, then initialize the password store
with that key:

```bash
gpg --list-secret-keys --keyid-format=long
pass init <gpg-key-id>
export ZFLEAK_VAULT_BACKEND=pass
pass --version
```

The selected key must be available to GPG whenever zfleak reads or writes a
secret.

### Encrypted file backend

The file backend requires `age` and `age-keygen`. On first
write, it creates a local identity under
`$HOME/.zfleak.d/vault/identity.txt` and stores one encrypted file
per vault key. Keep the identity private and backed up.

Verify the prerequisites before selecting it:

```bash
command -v age
command -v age-keygen
zfleak --backend file vault-backend
```

Select a backend for one invocation:

```bash
zfleak --backend file vault-backend
zfleak --backend file run demo -- your-application-command
```

Environment overrides:

- `ZFLEAK_VAULT_BACKEND`: `keychain`, `pass`, or
  `file`
- `ZFLEAK_VAULT_FILE_DIR`: alternate encrypted-file directory
- `ZFLEAK_KEYCHAIN`: alternate macOS Keychain target

### Migrate plaintext values

Migrate an active project's exported assignments:

```bash
zfleak migrate demo --to-backend file
```

The command rewrites every active single-line
`export NAME=value` assignment into a secret reference. It does not
select only obviously sensitive names, does not evaluate shell expansion, and
does not provide a dry run or backup. Review the result and ensure the target
backend is ready before running it.

The `ZFLEAK_SENSITIVE=true` control variable is preserved by
migration, so the sensitive-project block remains active.

## Command Reference

### Global options

```text
zfleak [--backend <backend>] <command> [arguments...]
```

`--backend <backend>` selects `keychain`, `pass`,
or `file` for that invocation. It must appear before the command.
The default is automatic backend selection.

### `zfleak new-project <project-name> [path]`

Create a new active project config. `<project-name>` is required and
must match `^[A-Za-z0-9_-]+$`. If `[path]` is supplied, it
is stored for auto-detection. The directory is not created.

```bash
zfleak new-project api "$HOME/work/api"
```

### `zfleak register-path <project-name> <path>`

Register or replace the auto-detection path for an existing project. The
project config must already exist; the path itself is not validated.

```bash
zfleak register-path api "$HOME/work/api"
```

### `zfleak list`

List active and archived projects. This command takes no documented options.

### `zfleak edit <project-name>`

Open an active or archived config using `$EDITOR`, then `vim`
or `nano` as a fallback. It fails if no project or usable editor is
available.

### `zfleak show <project-name> [--reveal]`

Display an active or archived config. Without `--reveal`, exported
values are masked. The flag must appear after the project name. Sensitive
projects require the reveal passphrase; non-sensitive projects do not.

### `zfleak archive <project-name>`

Move an active config into `.archive` and remove its auto-detection
mapping. It does not ask for confirmation.

### `zfleak restore <project-name>`

Move an archived config back to the active directory. It does not restore the
old auto-detection mapping; run `register-path` again if needed.

### `zfleak set-passphrase`

Interactively create or replace the reveal passphrase. It takes no arguments
and stores only a hash in the config directory.

### `zfleak unlock`

Clear a reveal lockout. If no lockout exists, it reports that nothing is
locked. Clearing an existing lockout requires OS authentication on macOS.

### `zfleak vault-backend`

Print the resolved backend name. It does not test backend credentials,
initialization, or secret keys.

### `zfleak migrate <project-name> --to-backend <backend>`

Move every matching active `export NAME=value` line into the selected
backend and replace it with a reference. `<backend>` is required.
Supported values are `keychain`, `pass`, and `file`.

### `zfleak run <project-name> -- <command...>`

Run a child command with project assignments and resolved secret references.
The `--` separator and a command are required.

```bash
zfleak run api -- python -c 'import os; print(os.environ["DB_HOST"])'
```

The child inherits the caller's existing environment and overlays the project
values. The config is parsed rather than sourced, so shell functions,
command substitutions, and variable expansion are not applied. The child's
exit status is returned by `zfleak`.

### `zfleak help` and `zfleak version`

`help`, `-h`, and `--help` show the top-level help.
`version`, `-v`, and `--version` show the version.
The command aliases are:

- `new` for `new-project`
- `register` for `register-path`
- `ls` for `list`
- `cat` for `show`

## Shell Helpers

The installer adds these functions to the selected shell:

- `use-project <project-name>`: source a project into the current
  shell
- `list-projects`: list projects from the current shell
- `current-project`: show the loaded project
- `clear-project`: unset variables tracked from the loaded project

`use-project` executes the project file in the current shell and is
blocked for projects with the active sensitive marker. Auto-detection matches
an exact registered directory or one of its subdirectories.

## Troubleshooting

### `zfleak: command not found`

Source the RC file selected by the installer, or invoke the binary directly:

```bash
"$HOME/.local/bin/zfleak" --help
```

### Auto-detection does not activate

Confirm that the directory exists, the path is registered, and the shell
switcher was sourced after installation. Use `zfleak register-path`
to replace the mapping, then leave and re-enter the directory. Use
`use-project` to test loading without the hook.

### Sensitive project loading is blocked

This is expected for an active `ZFLEAK_SENSITIVE=true` marker. Run
the application through `zfleak run` instead.

### Reveal fails

- Run `zfleak set-passphrase` if no passphrase has been configured.
- Check the passphrase and remember that three failures lock reveal.
- On macOS, run `zfleak unlock` and provide the OS login password.
- Review `$HOME/.zfleak.d/.audit.log` for failed attempts.

### Secret resolution fails

Run `zfleak vault-backend`, verify the backend prerequisites, and
confirm that the referenced key exists. For the file backend, verify that the
identity and encrypted files are present under the configured vault directory.

### `run` rejects the command

Use the required separator and provide a command:

```bash
zfleak run <project-name> -- <command...>
```

### The editor cannot be started

Set `$EDITOR` to an installed editor, or install `vim` or
`nano`.

## Exit Status

- `0`: command completed successfully
- `1`: validation, project, backend, authentication, or reveal error
- `run`: returns the child command's exit status, which can be any
  value chosen by that command

Because a child command can also return `1`, inspect the command
output when distinguishing a child failure from a `zfleak` error.
