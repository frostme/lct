secret_path=${args[path]}

if ! secret_path=$(to_home_tilde_path "$secret_path"); then
  echo "❌ ERROR: Secret path must resolve inside HOME" >&2
  exit 1
fi

if [[ -z "$secret_path" || "$secret_path" == "~" ]]; then
  echo "❌ ERROR: Secret path is required" >&2
  exit 1
fi

ensure_config_defaults
SECRET_PATH="$secret_path" yq -i '.secrets = (.secrets // []) | .secrets |= map(select(. != env(SECRET_PATH)))' "$LCT_CONFIG_FILE"
echo "Removed secret path: $secret_path"
