command_not_found_handler() {
    [[ -o interactive ]] || return 127

    local text="$*"
    [[ -n "$text" ]] || return 127
    [[ "$text" != *$'\n'* && "$text" != *$'\r'* ]] || return 127

    miyu --shell-intercept --shell zsh -- "$@" 2>/dev/null
    return 127
}
