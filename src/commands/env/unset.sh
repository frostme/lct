env_key=${args[key]}
env_key_regex='^[A-Za-z_][A-Za-z0-9_]*$'

if [[ ! $env_key =~ $env_key_regex ]]; then
  printf "Invalid environment key: %s\n" "$env_key" >&2
  exit 1
fi

unescape_sh_value() {
  local value=$1
  if [[ $value == \'*\' ]]; then
    value=${value:1:${#value}-2}
    value=${value//$'\'"\'/'\'}
  fi
  printf '%s' "$value"
}

envKey="$env_key" yq -i 'del(.[strenv(envKey)])' "$LCT_ENV_FILE"
unset -v "$env_key"
while IFS= read -r line; do
  if [[ $line =~ ^export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
    key=${BASH_REMATCH[1]}
    value=${BASH_REMATCH[2]}
    if [[ ! $key =~ $env_key_regex ]]; then
      printf "Invalid environment key in output: %s\n" "$key" >&2
      exit 1
    fi
    value=$(unescape_sh_value "$value")
    export "$key=$value"
  fi
done < <(send_environment)

send_reload
