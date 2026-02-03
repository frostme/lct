get_environment() {
  yq -r 'to_entries | .[] | "export \(.key)=\((.value|tostring)|@sh)"' "$LCT_ENV_FILE"
}

send_environment() {
  get_environment | envsubst
}
