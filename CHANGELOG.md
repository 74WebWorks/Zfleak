# Changelog

All notable changes to zfleak will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-05

### Added
- Initial release of zfleak
- CLI tool with 8 core commands (new-project, register-path, list, edit, show, archive, restore, help)
- Automatic project detection based on current directory
- Manual project switching with `use-project` command
- Project configuration templates
- Archive system for inactive projects
- Environment variable tracking and cleanup
- Dynamic path registration via projects.conf
- Installation script for easy setup
- Comprehensive documentation

### Features
- Zero-configuration startup
- Portable across machines
- Git-friendly configuration management
- Support for multiple projects
- Team collaboration support
- Custom configuration directory support via ZFLEAK_CONFIG_DIR

## [1.0.1]

### Added
- Updated README installation instructions with valid GitHub repository links (74WebWorks/Zfleak)
- Added remote installation option with one-liner bash command
- Updated all documentation references to use correct GitHub organization
- Bash compatibility - zfleak now works seamlessly with Bash in addition to Zsh
- Automatic shell detection during installation (Bash/Zsh)
- Bash-specific switcher library for optimal compatibility
- Support for .bashrc and .bash_profile configuration
- Cross-platform support verified for Linux and macOS

### Changed
- Improved installer to detect and configure appropriate shell RC files
- Enhanced shell reload instructions to cover both Bash and Zsh

### Fixed
- Removed `clear` command from installer for better compatibility
- Fixed `read` command compatibility issues across different environments

### Planned
- Shell completion (zsh/bash)
- Project templates (Django, Flask, Node.js, etc.)
- Environment variable encryption
- Integration with direnv
- Export to .env file
- Project groups/categories
- Hooks for project switching
