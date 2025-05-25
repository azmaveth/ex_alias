# ExAlias Tasks

## Completed

### Core Functionality
- [x] Alias definition and storage
- [x] Basic command expansion with argument appending
- [x] Command expansion with recursive support
- [x] Circular reference detection
- [x] JSON persistence
- [x] Pure functional core (ExAlias.Core)
- [x] GenServer wrapper for stateful usage
- [x] Reserved command protection
- [x] Comprehensive test coverage

### Features
- [x] Store multiple commands in aliases
- [x] Nested alias expansion
- [x] Validation with detailed error messages
- [x] List and remove operations
- [x] Automatic file creation on first use
- [x] Thread-safe operations via GenServer

## Todo

### Core Features Not Yet Implemented
- [ ] Parameter substitution with $1, $2, etc.
- [ ] Placeholder support with {} syntax
- [ ] Sequential execution of multi-command aliases
- [ ] Command chaining with proper error handling

### Features
- [ ] Alias import/export functionality
- [ ] Alias categories or namespaces
- [ ] Conditional aliases (based on context)
- [ ] Alias usage statistics
- [ ] Alias versioning/history
- [ ] Global vs local alias scopes
- [ ] Alias templates with defaults

### Advanced Parameter Handling
- [ ] Named parameters (e.g., $name, $file)
- [ ] Optional parameters with defaults
- [ ] Parameter validation rules
- [ ] Variadic parameters ($@, $*)
- [ ] Parameter transformation functions
- [ ] Environment variable expansion

### Integration Features
- [ ] Shell-style alias expansion
- [ ] Compatibility with bash/zsh aliases
- [ ] Integration with system commands
- [ ] Alias completion suggestions
- [ ] Alias discovery (suggest based on usage)

### Storage Enhancements
- [ ] Alternative storage backends (ETS, DETS, SQLite)
- [ ] Alias synchronization across instances
- [ ] Encrypted alias storage
- [ ] Alias backup and restore
- [ ] Migration between storage formats

### Developer Experience
- [ ] Mix tasks for alias management
- [ ] IEx helpers for interactive use
- [ ] Alias debugging mode
- [ ] Performance profiling for complex aliases
- [ ] Alias complexity warnings

### Documentation
- [ ] Comprehensive usage guide
- [ ] Integration examples
- [ ] Best practices for alias design
- [ ] Performance considerations
- [ ] Security guidelines

## Future Considerations

- [ ] DSL for complex alias definitions
- [ ] Macro support for compile-time aliases
- [ ] Integration with other CLI frameworks
- [ ] Alias sharing/marketplace
- [ ] AI-powered alias suggestions

## Notes

- The library focuses on being a robust, reusable alias system
- Should work well in CLI tools, chatbots, and automation scripts
- Performance is important for recursive expansion
- Security considerations for command injection prevention