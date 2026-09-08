#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lib_dir="$project_root/lib"

# Create the app's standard source tree without overwriting existing files.
directories=(
  "$lib_dir/app"
  "$lib_dir/bloc"
  "$lib_dir/models"
  "$lib_dir/repositories"
  "$lib_dir/screens"
  "$lib_dir/services"
  "$lib_dir/utils"
  "$lib_dir/widgets"
)

for directory in "${directories[@]}"; do
  mkdir -p "$directory"
done

files=(
  "$lib_dir/app/app.dart"
  "$lib_dir/app/routes.dart"
  "$lib_dir/app/theme.dart"
  "$lib_dir/models/.gitkeep"
  "$lib_dir/repositories/.gitkeep"
  "$lib_dir/screens/.gitkeep"
  "$lib_dir/services/.gitkeep"
  "$lib_dir/utils/.gitkeep"
  "$lib_dir/widgets/.gitkeep"
)

for file in "${files[@]}"; do
  if [[ ! -e "$file" ]]; then
    touch "$file"
  fi
done

printf 'lib/ tree is ready at %s\n' "$lib_dir"
