env_key=${args[key]}
env_value=${args[value]}

yq -i ".${env_key} = \"${env_value}\"" $LCT_ENV_FILE
eval "$(send_environment)"
