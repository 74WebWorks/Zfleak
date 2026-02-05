# Contributing to zfleak

Thank you for your interest in contributing to zfleak! This document provides guidelines and instructions for contributing.

## Code of Conduct

This project follows a simple code of conduct: Be respectful, be constructive, and help make this tool better for everyone.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue on GitHub with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior vs actual behavior
- Your environment (OS, zsh version, etc.)
- Any relevant error messages

### Suggesting Features

Feature suggestions are welcome! Please:
- Check if the feature has already been requested
- Clearly describe the feature and its use case
- Explain how it would benefit users

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/yourusername/zfleak.git
cd zfleak

# Install locally for testing
./install.sh

# Make your changes and test
zfleak help
```

### Code Style

- Use 4 spaces for indentation
- Add comments for complex logic
- Follow existing code structure
- Keep functions focused and single-purpose
- Use descriptive variable names

### Testing

Before submitting a PR:
- Test all commands work correctly
- Test auto-detection functionality
- Test with multiple projects
- Verify shell reload works properly
- Check for any error messages

## Project Structure

```
zfleak/
├── bin/
│   └── zfleak           # Main CLI tool
├── lib/
│   └── switcher.zsh     # Project switcher library
├── templates/           # Future: Project templates
├── install.sh           # Installation script
├── README.md
├── LICENSE
├── CHANGELOG.md
└── CONTRIBUTING.md
```

## Release Process

1. Update CHANGELOG.md
2. Update version in bin/zfleak
3. Create a git tag
4. Push to GitHub
5. Create a release on GitHub

## Questions?

Feel free to open an issue for any questions about contributing!
