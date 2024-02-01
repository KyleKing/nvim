#!/bin/zsh

# https://semgrep.dev/r?lang=Lua
semgrep ci --autofix --config="r/generic.unicode.security.bidi.contains-bidirectional-characters"

# Too many false positives
#   Requires cloning `ligurio/semgrep-rules`
# semgrep scan --config="~/Developer/local-code/semgrep-rules/rules/lua"

# PLANNED: consider SemGrep rule for require() or not (e.g. the initial install will fail when telescope isn't available)
#   And look into lua stylistic enforcement for variable naming conventions (e.g. snake_case vs. camelCase) - stylua?
#   And any type enforcement
