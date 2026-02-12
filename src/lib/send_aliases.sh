get_aliases() {
  yq -r '(. // {}) | to_entries | map("alias " + .key + "=" + (.value|@sh)) | .[]' "$LCT_ALIAS_FILE"
}

send_aliases() {
  get_aliases
}
