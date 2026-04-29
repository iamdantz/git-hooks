# Git Hooks Manager

A lightweight, secure, and modular Git hooks manager written in Bash. This tool allows you to easily install, manage, and version your Git hooks both locally and globally.

## Features

- **Secure**: All downloads are verified via SHA256 checksums to prevent MITM attacks.
- **Modular**: Hooks are isolated in their own directories, managed by a central dispatcher.
- **Flexible Scope**: Support for local repositories, global configuration, or recursive installation across multiple projects.
- **Version Control Friendly**: Optional support for storing hooks in a `.githooks` directory for easier team sharing.
- **Self-Configuring**: Hooks can include optional setup scripts for automated environment preparation.

## Installation

To install a hook, use the `install.sh` script. You can point it to your own fork by setting the `GIT_HOOKS_REPO` environment variable.

### Remote Installation (Quick Start)

You can run the installer directly without cloning the repository. Copy and paste the following command into your terminal:

```bash
curl -sSL https://raw.githubusercontent.com/iamdantz/git-hooks/main/install.sh | bash -s -- post-commit-congrats.sh
```

*Note: You can replace `post-commit-congrats.sh` with any available hook name and add any API flags like `--global` or `--recursive` after the hook name.*

### Local Installation

If you have already cloned the repository:

```bash
# Install a hook in the current repository
./install.sh <hook-filename>

# Install a hook with a custom path or parameters (for hooks that support it)
./install.sh <hook-filename> --path /custom/path
```

## API Reference

The `install.sh` script accepts several flags to control where and how hooks are installed.

| Flag | Short | Description |
| :--- | :--- | :--- |
| `--local` | | (Default) Installs the hook in the current repository's `.git/hooks` folder. |
| `--global` | | Installs the hook globally in `~/.config/git/hooks/` and configures `core.hooksPath`. |
| `--versioning` | `-v` | Installs hooks in a `.githooks/` directory at the project root. Also accepts `--version-enabled` or `versioning=true`. |
| `--recursive` | `-R` | Finds all first-level git repositories in the current directory and installs the hook in all of them (local scope only). |

### Argument Passing
Any arguments provided **after** the `<hook-filename>` are passed directly to the hook's setup script (if it exists). This allows for hook-specific configuration during installation.

## Available Hooks

### `post-commit-sync-activity.sh`
Synchronizes your commit activity to a "shadow" repository. This is useful for maintaining a contribution graph on a personal account when working on private or corporate repositories.

- **Installation Example**:
  ```bash
  ./install.sh post-commit-sync-activity.sh --path ~/projects/personal-activity --remote git@github.com:user/activity-repo.git
  ```
- **Specific Flags**:
  - `--path <dir>`: Specifies the destination repository where activity logs will be pushed. (Default: `~/.config/git/dev/shadow-repo`)
  - `--remote <url>`: (Optional) Sets the git remote origin for the shadow repository.

### `post-commit-congrats.sh`
A simple hook that prints a congratulatory message after every successful commit.

- **Installation Example**:
  ```bash
  ./install.sh post-commit-congrats.sh
  ```

## Project Structure

```text
.
├── core/
│   └── dispatcher.sh          # Orchestrates multiple hooks of the same type
├── hooks/
│   ├── post-commit-xxx.sh     # The hook logic
│   └── post-commit-xxx.setup.sh # (Optional) Installation-time setup logic
├── install.sh                 # Main installation entry point
└── checksums.sha256           # Integrity manifest
```

## Contributing

We welcome contributions! To add a new hook:

1. **Create the Hook**: Add your script to the `hooks/` directory. Use the naming convention `[type]-[name].sh` (e.g., `pre-push-linter.sh`).
2. **(Optional) Add Setup**: If your hook needs configuration (like creating directories or setting git configs), create a `hooks/[type]-[name].setup.sh`.
3. **Update Checksums**:
   ```bash
   sha256sum hooks/your-hook.sh >> checksums.sha256
   ```
4. **Submit a PR**: Detailed explanations of the hook's purpose are appreciated.

---