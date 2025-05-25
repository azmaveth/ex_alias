# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-27

### Added
- Initial release of ExAlias
- Core functional module for stateless alias management
- GenServer wrapper for stateful alias management
- Command alias definition with validation
- Recursive alias expansion with circular reference detection
- Parameter substitution support
- JSON persistence for aliases
- Reserved command protection
- Comprehensive error handling
- Full test coverage
- Documentation and examples

### Features
- Define simple command aliases
- Create command sequences (aliases that expand to multiple commands)
- Support for nested aliases (aliases referencing other aliases)
- Automatic circular reference detection
- Parameter passing to aliased commands
- Load and save aliases from/to JSON files
- Optional GenServer for supervised alias management
- Pure functional core for library integration