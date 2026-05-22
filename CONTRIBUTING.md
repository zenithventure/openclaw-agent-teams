# Contributing to OpenClaw Agent Teams

Thank you for your interest in contributing! This document outlines the process for contributing to this repository.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)

## Code of Conduct

Be respectful, inclusive, and constructive. We welcome contributions from everyone.

## How Can I Contribute?

### Reporting Issues

- Check existing issues before opening a new one
- Use a clear, descriptive title
- Include steps to reproduce if applicable
- Mention your environment (OS, Node.js version, OpenClaw version)

### Suggesting Enhancements

- Open an issue with the `enhancement` label
- Describe the problem you're trying to solve
- Explain why your solution would be useful

### Contributing Code

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes
4. Submit a pull request

## Development Workflow

We follow a **trunk-based development** workflow:

1. **Branch from `main`** — All work happens in feature branches
2. **Small, focused changes** — Each PR should do one thing well
3. **Squash merge** — We squash merge to keep history clean

### Branch Naming

Use descriptive branch names with prefixes:

| Prefix | Example | Use Case |
|--------|---------|----------|
| `feature/` | `feature/add-metrics-team` | New features |
| `fix/` | `fix/systemd-unit-path` | Bug fixes |
| `docs/` | `docs/update-readme` | Documentation |
| `refactor/` | `refactor/simplify-bootstrap` | Code cleanup |

### Commit Messages

Write clear, concise commit messages:

```
Add CONTRIBUTING.md for contribution guidelines

- Include trunk-based workflow documentation
- Add branch naming conventions
- Document PR process

Fixes #22
```

## Pull Request Process

### Before Submitting

- [ ] Branch is up to date with `main`
- [ ] Changes are tested locally
- [ ] Documentation is updated if needed
- [ ] Commit messages are clear

### PR Template

When you open a PR, include:

1. **Summary** — What changes does this PR make?
2. **Why** — What problem does this solve?
3. **Testing** — How did you test this?
4. **Screenshots** — If applicable

### Review Process

1. A maintainer will review your PR
2. Address any feedback
3. Once approved, a maintainer will merge

### Example PRs

- [#28](https://github.com/zenithventure/openclaw-agent-teams/pull/28) — Bug fix for systemd user sessions
- [#29](https://github.com/zenithventure/openclaw-agent-teams/pull/29) — Refactor for non-interactive shell support
- [#30](https://github.com/zenithventure/openclaw-agent-teams/pull/30) — Add service patch for OpenClaw 3.2

## Style Guidelines

### Shell Scripts

- Use `#!/usr/bin/env bash` shebang
- Enable strict mode: `set -euo pipefail`
- Use `[[ ]]` for tests, not `[ ]`
- Quote variables: `"$VAR"` not `$VAR`
- Add comments for complex logic

### Agent Configurations

- Use clear, descriptive agent IDs
- Include `IDENTITY.md`, `SOUL.md`, `USER.md` for each agent
- Keep `HEARTBEAT.md` focused on actionable checks

### Documentation

- Use Markdown format
- Include code examples where helpful
- Keep lines under 80 characters when possible
- Update table of contents if adding sections

## Project Structure

```
openclaw-agent-teams/
├── bootstrap.sh          # Server setup script
├── install-team.sh       # Team deployment script
├── _template/            # Template for new teams
├── operator/             # Operator team config
├── product-builder/      # Product builder team config
├── modernizer/           # Modernizer team config
├── recruiter/            # Recruiter team config
├── real-estate/          # Real estate team config
└── accountant/           # Accountant team config
```

## Adding a New Team

1. Copy `_template/` directory
2. Rename to your team name
3. Update agent configurations
4. Add `setup.sh` script
5. Update `install-team.sh` if needed
6. Submit a PR

## Questions?

- Open an issue for questions
- Check existing documentation in `README.md` and `DO-SETUP.md`

---

Thank you for contributing! 🎉
