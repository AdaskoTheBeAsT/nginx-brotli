#!/bin/sh

printf 'Starting to generate config file...\n'

# Define the directory where the config file is located
CONFIG_DIR="/var/www"
BASENAME="env-config"

# Try to find the current cache-busted file (e.g., env-config.[hash].js)
CURRENT_FILE=$(ls $CONFIG_DIR/$BASENAME.*.js 2>/dev/null)

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
