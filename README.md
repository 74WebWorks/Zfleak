# zfleak

**Project Environment Manager for Bash & Zsh**

A lightweight, powerful CLI tool that manages project-specific environment variables with automatic detection and seamless switching between development environments.

## ✨ Features

- 🚀 **Zero Configuration Startup** - Works out of the box
- 🔍 **Automatic Project Detection** - Auto-loads environments when you `cd` into project directories
- 🛠️ **Powerful CLI** - Full-featured command-line interface
- 📦 **Portable** - Install once, use everywhere
- 🎨 **Template System** - Quick project setup with sensible defaults
- 🗂️ **Archive Management** - Keep old configs without cluttering active projects
- 🎯 **Clean & Fast** - Minimal overhead, maximum productivity
- 🐚 **Shell Compatible** - Works seamlessly with both Bash and Zsh on Linux and macOS

## 🎬 Quick Start

### Installation

#### From GitHub (Recommended)

```bash
# Clone the repository
git clone https://github.com/74WebWorks/Zfleak.git
cd Zfleak

# Run the installer (detects Bash or Zsh automatically)
./install.sh

# Reload your shell
source ~/.zshrc    # For Zsh
source ~/.bashrc   # For Bash
```

#### Remote Installation

```bash
# One-liner for remote installation
bash <(curl -s https://raw.githubusercontent.com/74WebWorks/Zfleak/main/install.sh)

# Reload your shell
source ~/.zshrc
```

### Create Your First Project

```bash
# Create a new project with auto-detection
zfleak new-project myapp ~/projects/myapp

# Navigate to your project
cd ~/projects/myapp
# 🔍 Detected project: myapp
# ✅ Loaded active project: myapp

# Your environment variables are now active!
```

## 📖 Documentation

### Table of Contents

- [Installation](#installation-1)
- [Basic Usage](#basic-usage)
- [Commands](#commands)
- [Configuration](#configuration)
- [Examples](#examples)
- [Advanced Features](#advanced-features)

### Installation

#### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/74WebWorks/Zfleak/main/install.sh | bash
```

#### Manual Install

1. Clone the repository:
   ```bash
   git clone https://github.com/74WebWorks/Zfleak.git ~/.zfleak-install
   ```

2. Run the installer:
   ```bash
   cd ~/.zfleak-install
   ./install.sh
   ```
   
   The installer automatically detects your shell (Bash or Zsh) and configures the appropriate files.

3. Reload your shell:
   ```bash
   # For Zsh
   source ~/.zshrc
   
   # For Bash
   source ~/.bashrc  # or ~/.bash_profile on macOS
   ```

### Basic Usage

#### Creating Projects

```bash
# Create a new project
zfleak new-project <name> [path]

# Example
zfleak new-project backend ~/work/mycompany/backend
```

This creates a configuration file with a template containing common environment variables.

#### Automatic Loading

Once a project is created and a path is registered, simply navigate to that directory:

```bash
cd ~/work/mycompany/backend
# 🔍 Detected project: backend
# ✅ Loaded active project: backend
```

#### Manual Switching

```bash
# Switch to a project
use-project backend

# View current project
current-project

# Clear environment
clear-project
```

### Commands

#### `zfleak new-project <name> [path]`

Create a new project configuration with optional auto-detection path.

**Examples:**
```bash
zfleak new-project webapp ~/projects/webapp
zfleak new-project api  # No auto-detection
```

#### `zfleak register-path <name> <path>`

Register or update the auto-detection path for an existing project.

**Example:**
```bash
zfleak register-path api ~/projects/api
```

#### `zfleak list`

List all projects (active and archived).

**Example output:**
```
Active Projects:

  • backend → /Users/you/work/backend
  • frontend → /Users/you/work/frontend
  • api (no auto-detection path)

Archived Projects:

  • old-project
```

#### `zfleak edit <name>`

Open a project's configuration in your editor.

**Example:**
```bash
zfleak edit backend
```

#### `zfleak show <name>`

Display a project's configuration.

**Example:**
```bash
zfleak show backend
```

#### `zfleak archive <name>`

Move a project to the archive (keeps config but removes from active list).

**Example:**
```bash
zfleak archive old-project
```

#### `zfleak restore <name>`

Restore an archived project to active status.

**Example:**
```bash
zfleak restore old-project
```

### Configuration

#### Project Configuration Files

Project configs are stored in `~/.zfleak.d/<project-name>.zsh`.

**Example configuration:**

```bash
# ~/.zfleak.d/backend.zsh
export FLASK_APP='backend.app:create_app()'
export FLASK_ENV=development

export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=backend_user
export DB_PASSWORD=dev_password
export DB_NAME=backend_dev

export API_KEY=your_api_key_here
export DEBUG=true
```

#### Path Registration

Paths are registered in `~/.zfleak.d/projects.conf`:

```
backend:/Users/you/work/backend
frontend:/Users/you/work/frontend
api:/Users/you/work/api
```

### Examples

#### Example 1: Flask Application

```bash
# Create project
zfleak new-project myflask ~/projects/myflask

# Edit configuration
zfleak edit myflask

# Add these lines:
# export FLASK_APP='myflask.app:create_app()'
# export FLASK_ENV=development
# export DATABASE_URL=postgresql://localhost/myflask

# Use it
cd ~/projects/myflask
flask run  # Uses your configured environment!
```

#### Example 2: Multiple Environments

```bash
# Create different environments for same project
zfleak new-project api-dev ~/projects/api
zfleak new-project api-staging
zfleak new-project api-prod

# Configure each differently
zfleak edit api-dev       # Add dev database
zfleak edit api-staging   # Add staging database
zfleak edit api-prod      # Add prod database

# Switch between them
use-project api-dev
use-project api-staging
use-project api-prod
```

#### Example 3: Team Configuration

```bash
# Share your zfleak config with your team
cd ~/.zfleak.d
git init
git add .
git commit -m "Team zfleak configuration"
git remote add origin https://github.com/yourteam/zfleak-config.git
git push -u origin main

# Team members install:
git clone https://github.com/yourteam/zfleak-config.git ~/.zfleak.d
source ~/.zshrc
```

### Advanced Features

#### Custom Configuration Directory

Set a custom location for zfleak configs:

```bash
export ZFLEAK_CONFIG_DIR="$HOME/my-custom-location"
```

#### Integration with Other Tools

```bash
# Use with Docker
docker run -e "$(env | grep DB_)" myimage

# Use with Make
make deploy DB_HOST=$DB_HOST DB_NAME=$DB_NAME

# Export to .env file
env | grep "^DB_\|^API_" > .env
```

#### Variable Tracking

zfleak tracks which variables it loads and automatically unsets them when switching projects:

```bash
use-project project-a  # Sets project-a variables
use-project project-b  # Unsets project-a vars, sets project-b vars
clear-project          # Unsets all project vars
```

## 🔧 Configuration

### Global Settings

Create `~/.zfleak.d/common.zsh` for settings shared across all projects:

```bash
# Common settings for all projects
export EDITOR=code
export DEFAULT_REGION=us-east-1
```

### Machine-Specific Settings

Create `~/.zfleak.local` for settings that shouldn't be in version control:

```bash
# Machine-specific secrets
export SECRET_API_KEY=abc123
export LOCAL_DEV_PATH=/custom/path
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

Built with ❤️ for developers who work across multiple projects.

## 📮 Support

- Report bugs: [GitHub Issues](https://github.com/74WebWorks/Zfleak/issues)
- Ask questions: [GitHub Discussions](https://github.com/74WebWorks/Zfleak/discussions)
