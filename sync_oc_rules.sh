#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_dir="$script_dir/rules"
target_dir="$script_dir/oc_rules"

mkdir -p "$target_dir"

# Remove all existing entries in oc_rules (including hidden files).
shopt -s dotglob nullglob
existing_entries=("$target_dir"/*)
if ((${#existing_entries[@]} > 0)); then
  rm -rf "${existing_entries[@]}"
fi
shopt -u dotglob nullglob

# Create symlinks in oc_rules for each .mdc file in rules, renamed to .md.
shopt -s nullglob
mdc_files=("$source_dir"/*.mdc)
for mdc_path in "${mdc_files[@]}"; do
  mdc_file="$(basename "$mdc_path")"
  md_name="${mdc_file%.mdc}.md"
  ln -s "../rules/$mdc_file" "$target_dir/$md_name"
done
shopt -u nullglob

echo "Synced ${#mdc_files[@]} rule file(s) into $target_dir"
