#!/bin/sh

# Example usage: ./env.sh a1 a2 a3
# This means: Only process .env variables whose names start with a1, a2, or a3.

printf 'Starting to generate config file...\n'

# Collect all prefixes passed to the script
PREFIXES="$@" # e.g., "a1 a2 a3"

# Define the directory where the config file is located
CONFIG_DIR="/var/www"
BASENAME="env-config"

# Find any cache-busted env-config files (e.g. env-config.[hash].js) recursively in subfolders
# We take only the first file returned by find. If none is found, CURRENT_FILE stays empty.
CURRENT_FILE="$(find "$CONFIG_DIR" -type f -name "${BASENAME}.*.js" 2>/dev/null | head -n 1)"

# If no cache-busted file is found, fall back to the default name
if [ -z "$CURRENT_FILE" ]; then
  echo "No cache-busted file found. Checking for the default config file."
  CURRENT_FILE="$CONFIG_DIR/$BASENAME.js"
fi

# If neither cache-busted nor default file exists, use the default name for output
if [ ! -f "$CURRENT_FILE" ]; then
  echo "No existing config file found. Using default name."
  CACHE_BUSTED_FILE="$CONFIG_DIR/$BASENAME.js"
else
  echo "Found existing config file: $CURRENT_FILE"
  CACHE_BUSTED_FILE="$CURRENT_FILE"
fi

# Recreate config file
rm -rf "$CACHE_BUSTED_FILE"
touch "$CACHE_BUSTED_FILE"

# Start building the output in a variable
output="window._env_ = {\n"

# Initialize a variable to track whether this is the first entry
first_entry=true

# Process each line in the .env file
while IFS= read -r line || [ -n "$line" ]; do
  # Skip empty lines or lines that do not contain '='
  if [ -z "$line" ] || [[ "$line" != *"="* ]]; then
    continue
  fi

  # Split on the first '=' only to handle cases where '=' exists in the value
  varname=$(echo "$line" | cut -d '=' -f 1)
  varvalue=$(echo "$line" | cut -d '=' -f 2-)

  # Trim surrounding quotes if present
  varvalue=$(echo "$varvalue" | sed 's/^"//' | sed 's/"$//')

  # Escape backslashes and double quotes in the value (but leave %2B intact)
  varvalue=$(echo "$varvalue" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

  # If it's the Content-Security-Policy variable, update Nginx headers *only if* value is not empty or "null"
  if [ "$varname" = "CONTENT_SECURITY_POLICY" ]; then
    # Check if the variable is non-empty and not "null"
    if [ -n "$varvalue" ] && [ "$varvalue" != "null" ]; then
      # Replace the existing CSP line in headers.conf with the new value
      sed -i "s|^more_set_headers \"Content-Security-Policy:.*|more_set_headers \"Content-Security-Policy: $varvalue\"|g" /etc/nginx/conf.d/headers.conf
    fi
    continue
  fi

  # Only proceed if varname starts with one of the prefixes in $PREFIXES
  should_skip=true

  # Iterate through each prefix provided to the script
  for prefix in $PREFIXES; do
    # Check if varname starts with this prefix
    case "$varname" in
    $prefix*)
      should_skip=false
      break
      ;;
    esac
  done

  # If it didn't match any prefix, skip processing this variable
  if [ "$should_skip" = true ]; then
    continue
  fi

  # Build the key-value pair string
  if [ "$first_entry" = true ]; then
    output="$output  \"$varname\": \"$varvalue\""
    first_entry=false
  else
    output="$output,\n  \"$varname\": \"$varvalue\""
  fi

done <.env

# Close the JSON object in the output
output="$output\n}"

# Write the final content to the file using `echo -e` to interpret newlines
echo -e "$output" >"$CACHE_BUSTED_FILE"

echo "Generated $CACHE_BUSTED_FILE successfully."
