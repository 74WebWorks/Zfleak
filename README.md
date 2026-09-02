# zfleak

Project environment manager for Bash and Zsh. Keep project-specific
environment variables in local configuration files, switch them automatically
when changing directories, or expose them only to one child process.

## Quick Start

The installer requires Bash. The `zfleak` CLI requires Zsh, including
when it is called from Bash.

```bash
git clone https://github.com/74WebWorks/Zfleak.git "$HOME/.zfleak-src"
cd "$HOME/.zfleak-src"
printf 'y\n' | ./install.sh
```

Source the shell RC file named by the installer:

```bash
# Zsh
source "$HOME/.zshrc"

# Bash when the installer selected .bash_profile
# source "$HOME/.bash_profile"

# Bash otherwise
# source "$HOME/.bashrc"
```

Create a directory and project configuration:

```bash
demo_dir="$HOME/work/zfleak-demo"
mkdir -p "$demo_dir"
zfleak new-project demo "$demo_dir"
printf '\nexport ZFLEAK_DEMO=ready\n' >> "$HOME/.zfleak.d/demo.zsh"
use-project demo
printf '%s\n' "$ZFLEAK_DEMO"
clear-project
```

For remote installation, use a command that leaves the installer's
confirmation prompt connected to the terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/74WebWorks/Zfleak/main/install.sh)
```

The full setup guide, security model, backend setup, command reference, and
troubleshooting steps are in [USAGE.md](USAGE.md).

## Features

- Automatic project detection from registered directories
- Manual shell switching with cleanup between projects
- Masked configuration display by default
- Child-process-only execution for sensitive environments
- macOS Keychain, `pass`, and encrypted-file vault backends
- Project archiving and restoration

## Security

### Threat model

zfleak reduces accidental exposure of project secrets. It does not protect
against a local user who can read your home directory, a compromised backend,
or a child process that intentionally reads its environment.

- Keep production values in a vault reference instead of a plaintext config.
- Mark sensitive projects with `export ZFLEAK_SENSITIVE=true`.
- Use `zfleak run <project-name> -- <command...>` so values are not exported
  into the calling shell.
- `zfleak show <project-name>` masks exported values unless reveal is
  explicitly requested.
- Do not commit `~/.zfleak.d`; it can contain plaintext config, audit records,
  and the file-backend identity.

### Protection by phase

- Phase 0 adds regression tests and linting for the security work.
- Phase 1 hardens file permissions, project-name validation, path matching,
  and default output masking.
- Phase 2 adds sensitive-project gates, reveal authentication, lockout, and
  audit logging.
- Phase 3 adds named secret references and a vault backend interface.
- Phase 4 adds macOS Keychain, `pass`, and encrypted-file backends, plus
  plaintext migration.
- Phase 5 keeps sensitive project values in the `run` child process only.
- Phase 6 documents safe setup and migration practices.

### Backend setup

- **macOS:** `keychain` is selected by default and uses the built-in
  `security` command. No separate vault setup is required.
- **Linux:** `pass` is selected when it is installed and initialized. Install
  `pass` and GnuPG, create or select a GPG key, then run
  `pass init <gpg-key-id>`.
- **macOS or Linux:** the `file` backend requires `age` and `age-keygen`.
  It creates an encrypted per-key store on first write.

Check or override selection with:

```bash
zfleak vault-backend
ZFLEAK_VAULT_BACKEND=file zfleak run demo -- <command...>
```

See [USAGE.md](USAGE.md#vault-backends) for prerequisites, environment
variables, backend verification, and recovery steps.

### Migrate plaintext values

For an existing project, migrate its active exported assignments into a
selected backend:

```bash
zfleak migrate <project-name> --to-backend <backend>
```

The command replaces every matching `export NAME=value` line, except the
`ZFLEAK_SENSITIVE` marker, with a `# zfleak:secret` reference. It has no dry
run or backup, so review the config and verify the backend before and after
running it. See [the migration guide](USAGE.md#migrate-plaintext-values).

## Documentation

- [Usage guide](USAGE.md)
- [Changelog](CHANGELOG.md)
- [Contributing](CONTRIBUTING.md)

## Support

- [Report a bug](https://github.com/74WebWorks/Zfleak/issues)
- [Ask a question](https://github.com/74WebWorks/Zfleak/discussions)

## License

MIT. See [LICENSE](LICENSE).
