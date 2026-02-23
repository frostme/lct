alias_name=${args[alias]}

ALIAS_NAME="$alias_name" yq -i '(. // {}) | del(.[env(ALIAS_NAME)])' "$LCT_ALIAS_FILE"

send_reload
