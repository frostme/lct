env_key=${args[key]}
yq ".$env_key" $LCT_ENV_FILE
