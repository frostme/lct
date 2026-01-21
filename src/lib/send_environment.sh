send_environment() {
  echo "$(yq -r 'to_entries | .[] | "export \(.key)=\((.value|tostring)|@sh)"' "$LCT_ENV_FILE")"
}
