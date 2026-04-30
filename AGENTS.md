<instructions>
1. **Plan**: Analyze the hook requirement or architectural change. Verify that any modification to `core/dispatcher.sh` or `install.sh` remains strictly agnostic to individual hooks.
2. **Execute**: Implement the script.
   - New hooks must be named `[type]-[name].sh`.
   - Setup scripts (if required) must be named `[type]-[name].setup.sh`
3. **Validate**: Ensure the code does not contain hardcoded hook-specific logic in the core orchestration engine. Ensure all scripts output errors to `stderr` (`>&2`).
</instructions>

<constraints>
- **Verbosity**: Low. Provide direct solutions.
- **Language**: English for all technical terms, code, and variables.
- **Code Standards**:
  - All Bash scripts MUST start with `#!/usr/bin/env bash` followed immediately by `set -euo pipefail`.
  - Use POSIX-compliant standard Bash 4+ features.
  - Code must be uncommented unless explaining a complex regex.
- **Security**: Apply Least Privilege. New executable scripts must explicitly be assigned `chmod 755` (or equivalent restricted execution permissions). Do not leave open permissions.
</constraints>

<context>
## Codebase Overview
This project is a modular Git hooks manager. It separates hook orchestration (`core/dispatcher.sh`) from specific hook logic (`hooks/`) and provides a secure installer (`install.sh`).

## Core Architecture & Abstraction Principle

The Dispatcher and the Core MUST remain strictly agnostic to individual hooks. The orchestration engine does not care what hooks exist or how they work. Current and future hooks must adapt to the Dispatcher. Any new feature added to support a hook must be generalized.

## Dispatcher Hierarchy

The `core/dispatcher.sh` executes hooks in this specific order:

1. Global (`~/.config/git/hooks/*.d/`)
2. Local Versioned (`.githooks/*.d/`)
3. Local Private (`.git/hooks/*.d/`)

## Documentation

Docs available at [README.md](README.md).
</context>

<output_format>
Return strictly the necessary code blocks or terminal commands to solve the user's task.
If providing an architectural decision, use a concise bulleted list.
</output_format>

<final_instruction>
Review your plan against the Abstraction Principle and Security Constraints before writing any Bash code.
</final_instruction>

<lifecycle>
As this project evolves, this AGENTS.md file MUST be continuously updated to reflect new core features, relevant architectural changes, or evolving guidelines. Keeping this file aligned with the current project vision is critical for AI assistants to remain effective.
</lifecycle>
