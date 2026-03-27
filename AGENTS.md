# Void Linux Setup - Agent Guidelines

## Project Overview

This is a bash script project that bootstraps a UEFI Void Linux installation with BTRFS and LUKS encryption. The codebase is organized as:
- `main.sh` - Entry point with interactive menu
- `lib/` - Shared functions (globals.sh, helpers.sh)
- `modules/` - Feature modules (bootstrap.sh, post_install.sh)

## Build/Test/Lint Commands

### Linting (ShellCheck)
```bash
# Run shellcheck on all scripts
shellcheck main.sh lib/*.sh modules/*.sh

# Run with explicit shell dialect
shellcheck -s bash main.sh lib/*.sh modules/*.sh

# Check a specific file
shellcheck modules/bootstrap.sh
```

### Testing
No formal test framework is used. Testing is manual:
```bash
# Dry-run with verbose output (check what would be executed)
bash -n main.sh  # Syntax check only

# Run in a VM or container for actual testing
sudo bash main.sh
```

### Code Style Check
```bash
# Verify script permissions
ls -la *.sh lib/*.sh modules/*.sh
# Should have execute bit: -rwxr-xr-x
```

### Formatting (shfmt)
```bash
# Format all scripts with shfmt (default tab indentation)
shfmt -w main.sh lib/*.sh modules/*.sh

# Check formatting without modifying files
shfmt -l main.sh lib/*.sh modules/*.sh

# View diff of formatting changes
shfmt -d main.sh lib/*.sh modules/*.sh
```

## Code Style Guidelines

### Shell & Syntax
- Use `#!/usr/bin/env bash` shebang
- Always enable `set -e` at script start for fail-fast behavior
- Use `set -u` to catch undefined variables (optional but recommended)
- Prefer `[[ ]]` over `[ ]` for conditionals

### Formatting
- Use tab indentation (shfmt default)
- Keep lines under 100 characters when reasonable
- Add blank lines between function definitions
- Use consistent spacing around operators: `[[ "$var" = "value" ]]`

### Naming Conventions
- Functions: `snake_case` (e.g., `setup_luks`, `install_bootloader`)
- Variables: `UPPER_SNAKE_CASE` for globals, `lower_snake_case` for locals
- Use `local` keyword for function-scoped variables
- Prefix user-prompt functions with `prompt_` (e.g., `prompt_disk`)

### Imports/Source
- Source files with full path: `source "$SCRIPT_DIR/lib/globals.sh"`
- Use `shellcheck disable=SC1091` for sourced files without absolute paths
- Group sources at top of script, before any logic

### Error Handling
- Use `die "message"` for fatal errors (exits with code 1)
- Use `warn "message"` for non-fatal warnings
- Check return codes explicitly: `command || die "message"`
- Use `command -v` to verify dependencies before use

### User Input
- Use `read -rp` for prompts (read with prompt)
- Use `read -srp` for password input (silent)
- Validate user input immediately after collection
- Provide sensible defaults: `${VAR:-default}`

### Output Formatting
- Use `echo "==> Description"` for section headers
- Use `echo "    Detail"` for indented sub-items
- Keep messages concise and action-oriented

### Function Structure
- Start with section header echo
- Validate prerequisites at function start
- Return 0 implicitly (no explicit `return 0`)
- Keep functions focused on one responsibility

### Security
- Never hardcode passwords or secrets
- Use `chmod 000` for sensitive files (keys, etc.)
- Validate paths before operations: `[[ -b "$path" ]]`
- Check root when required: `check_root`

## Important Patterns

### XCHROOT Pattern
The `$XCHROOT` variable handles both live ISO and installed system contexts:
```bash
# Correct - works in both environments
$XCHROOT xbps-install -Sy package

# For complex commands
$XCHROOT bash -c "command1 && command2"
```

### Trap Cleanup
All scripts use `trap cleanup EXIT INT TERM` for consistent cleanup.

### Disk Operations
- Always validate disk exists: `[[ -b "$disk_path" ]]`
- Use `get_disk_path` helper to normalize disk paths
- Wipe disk before partitioning: `sfdisk --wipe always`

## Files Not To Modify
- `/home/jay/dev/void-setup/apps.md` - Package tracking list (user reference)
