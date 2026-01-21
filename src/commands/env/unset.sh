env_key=${args[key]}
yq -i "del(.${env_key})" $LCT_ENV_FILE
unset -v $env_key
eval "$(send_environment)"
