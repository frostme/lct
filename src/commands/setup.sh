echo $"autoload -Uz +X bashcompinit && bashcompinit"
printf '\n\n'
send_environment
printf '\n\n'
send_completions
printf '\n\n'
zoxide init zsh
printf '\n\n'
zellij setup --generate-auto-start zsh
