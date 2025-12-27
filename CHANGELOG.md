# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Retry logic with exponential backoff for transient API failures (429, 5xx)
- New environment variables: `YATTI_MAX_RETRIES`, `YATTI_TIMEOUT`, `YATTI_CONNECT_TIMEOUT`
- Comprehensive test coverage for edge cases (63 new tests):
  - Large payload handling (100KB+ queries)
  - Unicode and special character support (15 languages)
  - Error resilience for malformed responses
  - Retry mechanism validation
  - JSON input validation for user commands
  - GPG key fingerprint pinning verification
  - Interactive prompt timeout handling
- Man page documentation (`yatti-api.1`)
- Enhanced mock curl for retry testing in test suite
- Installer (`install.sh`) now installs man page and bash completion automatically

### Changed
- Optimized jq calls for improved performance (reduced redundant JSON parsing)
- Added curl connection timeouts (10s connect, 60s max)
- Use pre-increment in retry loop to avoid `set -e` arithmetic edge case
- Config directory now respects `$XDG_CONFIG_HOME` (FreeDesktop.org compliance)

### Fixed
- SC2030 bug: `temp_file` was assigned in subshell and lost (update function)
- jq exit status causing failure when contexts array is missing in verbose mode
- Duplicate `script_dir` variable declaration in `cmd_update()`

### Security
- JSON input validation for `users create` and `users update` commands (prevents injection)
- GPG key fingerprint pinning prevents MITM attacks during client updates
- Read timeouts (60s for prompts, 300s for API key input) prevent indefinite hangs

## [1.4.0] - 2025-12-15

### Added
- Unlimited query size support via file input (`-Q` flag)
- Stdin support for queries (`-q -` or auto-detect when piped)
- Size feedback for large queries (info at 10KB, warning at 100KB)
- URL validation to prevent API endpoint hijacking
- GPG signature verification for update downloads
- Masked API key display in version output (shows only last 4 characters)
- Symlink warnings when using query files
- Atomic file operations for API key storage using `install -m 600`
- 86 new tests for comprehensive coverage
- Path traversal prevention with `validate_path_segment()`
- Query parameter validation with `validate_query_param()`

### Changed
- Default model changed from gpt-5.1 to gpt-5.2
- Improved temp file security using `TMPDIR` environment variable
- Enhanced error messages throughout with `${var@Q}` safe quoting

### Security
- URL validation prevents endpoint hijacking attacks
- GPG signature verification on client updates
- Path traversal prevention in all user inputs
- Secure temp file handling with unique filenames via `mktemp`
- Atomic API key file creation prevents race conditions
- Symlink rejection for `SCRIPT_PATH` during updates

## [1.0.0] - 2025-11-16

### Added
- Initial release of YaTTi API Client
- Core CLI functionality for YaTTi REST API
- Commands: `configure`, `status`, `users`, `kb`, `query`, `history`, `get-query`, `docs`, `update`, `help`, `version`
- Bash completion support via `yatti-api.bash_completion`
- Comprehensive README documentation
- Query options: `--knowledgebase`, `--query`, `--top-k`, `--temperature`, `--model`, `--context-scope`, `--force-refresh`, `--context-only`, `--max-tokens`, `--prompt-template`, `--cache-ttl`, `--timeout`
- Multiple prompt templates: default, instructive, scholarly, concise, analytical, conversational, technical
- JSON and pretty output formats via `OUTPUT_FORMAT` environment variable
- Verbose mode via `VERBOSE` environment variable
- Color-coded terminal output with automatic detection
- Self-update mechanism with version comparison

#fin
