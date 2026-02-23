alias_name=${args[alias]}
alias_command=${args[command]}

ALIAS_NAME="$alias_name" ALIAS_COMMAND="$alias_command" yq -i '(. // {}) | .[env(ALIAS_NAME)] = strenv(ALIAS_COMMAND)' "$LCT_ALIAS_FILE"

send_reload
