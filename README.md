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

## Security Basics

- Do not commit `~/.zfleak.d` as a whole. It can contain plaintext
  config, reveal metadata, audit records, and the file-backend identity.
- Use `# zfleak:secret VAR=<vault-key>` for production secret
  references.
- Mark sensitive projects with `export ZFLEAK_SENSITIVE=true`.
- Use `zfleak run <project-name> -- <command...>` instead of
  `use-project` for sensitive projects.
- `zfleak show <project-name>` masks exported values unless reveal is
  explicitly requested.

## Documentation

- [Usage guide](USAGE.md)
- [Changelog](CHANGELOG.md)
- [Contributing](CONTRIBUTING.md)

## Support

- [Report a bug](https://github.com/74WebWorks/Zfleak/issues)
- [Ask a question](https://github.com/74WebWorks/Zfleak/discussions)

## License

MIT. See [LICENSE](LICENSE).
