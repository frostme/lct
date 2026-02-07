echo $"autoload -Uz +X bashcompinit && bashcompinit"
printf '\n\n'
send_environment
printf '\n\n'
send_completions
printf '\n\n'
send_plugin_completions
printf '\n\n'
send_plugin_setups
