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
append_unique "secrets" "$secret_path"
echo "Added secret path: $secret_path"
