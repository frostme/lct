env_key=${args[--key]:-""}
if [ -z "$env_key" ]; then
  yq -o=shell $LCT_ENV_FILE
else
  echo "$env_key=$(yq ".$env_key" $LCT_ENV_FILE)"
fi
