#!/bin/sh

# Example usage: ./env.sh a1 a2 a3
# This means: Only process .env variables whose names start with a1, a2, or a3.

# Add this at the top to exit on errors, unset variables, or pipeline failures.
set -euo pipefail

printf 'Starting to generate config file...\n'

# Ensure the script is called with at least one prefix.
if [ $# -eq 0 ]; then
  echo "Error: At least one prefix must be provided."
  exit 1
fi

# Collect all prefixes passed to the script
PREFIXES="$@" # e.g., "a1 a2 a3"

# Define the directory where the config file is located
CONFIG_DIR="/var/www"
BASENAME="env-config"

# Find any cache-busted file that starts with "env-config" and ends in ".js" recursively in subfolders
# We take only the first file returned by find. If none is found, CURRENT_FILE stays empty.
# This covers names like env-config.js, env-config-DgyoikIV.js, env-config.something.js, etc.
CURRENT_FILE="$(find "$CONFIG_DIR" -type f -name "${BASENAME}*.js" 2>/dev/null | head -n 1)"

if [ -n "$CURRENT_FILE" ]; then
  echo "Found existing file: $CURRENT_FILE"

  # Extract directory and filename
  FILE_DIR="$(dirname "$CURRENT_FILE")"
  FILE_BASENAME="$(basename "$CURRENT_FILE")" # e.g. env-config-DgyoikIV.js

  # Attempt to extract the suffix between "env-config" and ".js".
  # For example:
  #   env-config.js           -> (empty suffix)
  #   env-config-DgyoikIV.js  -> suffix = -DgyoikIV
  #   env-config.something.js -> suffix = .something
  #   env-configSomething.js  -> suffix = Something
  FILE_SUFFIX="$(echo "$FILE_BASENAME" | sed -n 's/^env-config\(.*\)\.js$/\1/p')"

  # Build the final path for writing
  # If there's a suffix, we'll use it; if it's empty, that means it was exactly "env-config.js"
  CACHE_BUSTED_FILE="$FILE_DIR/${BASENAME}${FILE_SUFFIX}.js"
else
  # 2) If no matching file is found, fall back to a standard env-config.js in /var/www
  echo "No file found that starts with env-config and ends with .js."
  DEFAULT_FILE="$CONFIG_DIR/$BASENAME.js"

  if [ -f "$DEFAULT_FILE" ]; then
    echo "Found existing default config file: $DEFAULT_FILE"
    CACHE_BUSTED_FILE="$DEFAULT_FILE"
  else
    # If neither is found, create a new file named env-config.js
    echo "No existing default config file found. Using $BASENAME.js in $CONFIG_DIR."
    CACHE_BUSTED_FILE="$DEFAULT_FILE"
  fi
fi

echo "Target config file for writing: $CACHE_BUSTED_FILE"

# Recreate config file
rm -rf "$CACHE_BUSTED_FILE"
touch "$CACHE_BUSTED_FILE"

# Start building the output in a variable
output="window._env_ = {\n"

# Initialize a variable to track whether this is the first entry
first_entry=true

# Process environment variables matching prefixes
for prefix in "$@"; do
  for varname in $(env | cut -d= -f1 | grep -E "^($prefix|CONTENT_SECURITY_POLICY)"); do
    varvalue="$(printenv "$varname")"

    if [ "$varname" = "CONTENT_SECURITY_POLICY" ]; then
      if [ -n "$varvalue" ] && [ "$varvalue" != "null" ]; then
        echo "Updating Content-Security-Policy in Nginx headers."
        # Replace the existing CSP line in headers.conf with the new value
        sed -i \
          "s|^\(more_set_headers \"Content-Security-Policy:\).*|\1 $varvalue\";|g" \
          /etc/nginx/conf.d/headers.conf
      fi
      continue
    fi

    varvalue="$(echo "$varvalue" | sed 's/\\/\\\\/g; s/"/\\"/g')"

    if [ "$first_entry" = true ]; then
      first_entry=false
      output="$output  \"$varname\": \"$varvalue\""
    else
      output="$output,\n  \"$varname\": \"$varvalue\""
    fi
  done
done

# Close the JSON object in the output
output="$output\n};"

# Write the final content to the file using `echo -e` to interpret newlines
echo -e "$output" >"$CACHE_BUSTED_FILE"

echo "Generated $CACHE_BUSTED_FILE successfully."
