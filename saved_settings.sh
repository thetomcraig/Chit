#!/usr/bin/env bash

# Utility for reading an writing strings to a file on disk

# The dir for this file
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Carriage return for string construction
cr=`echo $'\n.'`
cr=${cr%.}

get_or_set_saved_setting() {
  setting_file_name="${1}"
  user_prompt="${2}"

  # Try to get the saved setting
  setting_file="${__dir}"/"${setting_file_name}"
  saved_setting=$(get_saved_setting "${setting_file_name}")
  # If there is nothing found, prmopt user; write to file
  if [ "${saved_setting}" = "" ]; then
    read -rp "${user_prompt}" saved_setting
    echo "${saved_setting}" >> "${setting_file}"
  fi
  # Done, return the setting string to the caller function 
  echo "${saved_setting}"
}

get_saved_setting() {
  setting_file_name="${1}"

  saved_setting=""

  setting_file="${setting_file_name}"
  # If setting file is present, read the first line
  if [ -f "${setting_file}" ]; then
    saved_setting=$(sed -n 1p "${setting_file}")
  fi

  echo "${saved_setting}"
}

set_saved_setting() {
  setting_file_name="${1}"
  setting_value="${2}"

  setting_file="${setting_file_name}"

  echo "${setting_value}" > "${setting_file}"
}
