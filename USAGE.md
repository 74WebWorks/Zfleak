# zfleak Usage Guide

This document covers setup, day-to-day usage, and the command reference
for `zfleak`.

## 1. Setup

### 1.1 Prerequisites

- Bash or Zsh
- `git`
- `bats-core` and `shellcheck` if you want to run the repo checks

### 1.2 Install from a clone

```bash
git clone https://github.com/74WebWorks/Zfleak.git
cd Zfleak
./install.sh
```

Reload your shell after install:

```bash
source ~/.zshrc
# or
source ~/.bashrc
```

### 1.3 Remote install

```bash
bash <(curl -s https://raw.githubusercontent.com/74WebWorks/Zfleak/main/install.sh)
```

### 1.4 Verify the install

```bash
zfleak help
zfleak version
```

## 2. Files and directories

By default, zfleak stores its config under `~/.zfleak.d`.

Important paths:

- `~/.zfleak.d/<project>.zsh` project configs
- `~/.zfleak.d/projects.conf` auto-detection mappings
- `~/.zfleak.d/.archive/` archived project configs
- `~/.zfleak.d/vault/` encrypted-file backend storage
- `~/.zfleak.d/.audit.log` reveal failure audit log

You can override the config directory with:

```bash
export ZFLEAK_CONFIG_DIR="$HOME/custom-zfleak"
```

## 3. First project workflow

### 3.1 Create a project

```bash
zfleak new-project myapp ~/work/myapp
```

This creates `~/.zfleak.d/myapp.zsh` and registers the path for
auto-detection.

### 3.2 Add environment values

Edit the project file:

```bash
zfleak edit myapp
```

Typical values look like:

```bash
export FLASK_ENV=development
export DB_HOST=127.0.0.1
```

For production secrets, prefer vault references:

```bash
# zfleak:secret DB_PASSWORD=myapp/DB_PASSWORD
export ZFLEAK_SENSITIVE=true
```

### 3.3 Load a project into the shell

```bash
use-project myapp
```

### 3.4 Load a project in a child process only

```bash
zfleak run myapp -- env | grep DB_
```

Use `run` for sensitive projects or anytime you do not want secrets to
persist in the parent shell.

## 4. Secret handling

### 4.1 Masked output

```bash
zfleak show myapp
```

This masks exported values by default.

### 4.2 Reveal secret values

```bash
zfleak show myapp --reveal
```

Sensitive projects require the configured reveal passphrase before the
real values are printed.

### 4.3 Set the reveal passphrase

```bash
zfleak set-passphrase
```

### 4.4 Unlock after a reveal lockout

```bash
zfleak unlock
```

On macOS this uses OS authentication. On other platforms it reports that
unlock support is unavailable.

## 5. Vault backends

zfleak resolves a backend automatically unless you override it:

- `keychain` on macOS
- `pass` if installed
- `file` as the fallback

Check the active backend:

```bash
zfleak vault-backend
```

Override per command:

```bash
zfleak --backend file vault-backend
zfleak --backend file run myapp -- printenv DB_PASSWORD
```

Environment variable override:

```bash
export ZFLEAK_VAULT_BACKEND=file
```

### 5.1 Secret reference format

Use this line in a project config:

```bash
# zfleak:secret DB_PASSWORD=myapp/DB_PASSWORD
```

The left side is the exported variable name. The right side is the vault
key.

### 5.2 Migrate plaintext secrets

```bash
zfleak migrate myapp --to-backend file
```

This rewrites matching `export VAR=value` lines into secret references
and stores the values in the target backend.

## 6. Command reference

### `zfleak new-project <name> [path]`

Create a new project config.

Example:

```bash
zfleak new-project api ~/work/api
```

### `zfleak register-path <name> <path>`

Register or update the auto-detection path for an existing project.

Example:

```bash
zfleak register-path api ~/work/api
```

### `zfleak list`

List active and archived projects.

### `zfleak edit <name>`

Open the project config in `$EDITOR`.

### `zfleak show <name> [--reveal]`

Show the project config, masked by default.

### `zfleak archive <name>`

Move a project config into `.archive`.

### `zfleak restore <name>`

Move an archived project back into the active config directory.

### `zfleak set-passphrase`

Set the reveal passphrase used by `show --reveal` on sensitive projects.

### `zfleak unlock`

Clear a reveal lockout after failed passphrase attempts.

### `zfleak vault-backend`

Print the resolved backend name.

### `zfleak migrate <name> --to-backend <backend>`

Move plaintext `export` values into the selected backend.

### `zfleak run <name> -- <command...>`

Run a child command with the project's environment only.

Example:

```bash
zfleak run api -- python -c 'import os; print(os.environ["DB_HOST"])'
```

### `zfleak help`

Show the built-in command help.

### `zfleak version`

Show the current version string.

## 7. Shell helpers

These functions come from the switcher libraries that the installer adds
to your shell startup file:

- `use-project <name>` load a project into the current shell
- `list-projects` show available projects
- `current-project` show the active project
- `clear-project` unload the current project

Auto-detection uses your current directory and the mappings in
`projects.conf`.

## 8. Recommended production workflow

1. Create the project with `zfleak new-project`.
2. Mark it sensitive with `export ZFLEAK_SENSITIVE=true`.
3. Store secrets in a backend using `# zfleak:secret ...`.
4. Use `zfleak run <project> -- <command...>` instead of `use-project`.
5. Use `zfleak show <project> --reveal` only when you actually need to
   inspect the config.

