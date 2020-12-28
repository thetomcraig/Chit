#!/usr/bin/env bash

# Homebrew build/install steps will make and populate this folder
CONFIG_DIR=${HOME}/.config/chit

# This is the file kitty will source to apply colors
# Chit will cp other files to this path when changing themes
# Must have the follwing line in your kitty.conf:
#  include ./theme.conf
KITTY_THEME_CONF_PATH="${HOME}/.config/kitty/theme.conf"


##################
# SETTINGS UTILS #
##################
getSavedSetting() {
  setting_file_name="${1}"

  saved_setting=""

  setting_file="${setting_file_name}"
  # If setting file is present, read the first line
  if [ -f "${setting_file}" ]; then
    saved_setting=$(sed -n 1p "${setting_file}")
  fi

  echo "${saved_setting}"
}

setSavedSetting() {
  setting_file_name="${1}"
  setting_value="${2}"

  echo "${setting_value}" > "${setting_file_name}"
}


##################
# TERMINAL UTILS #
##################
getTerminalEmulator() {
  # Name of the current terminal emulator application
  terminal_emulator=$(osascript -e 'tell application "System Events"' \
                                -e 'set frontApp to name of first application process whose frontmost is true' \
                                -e 'end tell')
  echo "${terminal_emulator}"
}

kittyThemeIsApplied() {
  # Check the colors being used in the kitty session
  # If they do not match the theme set by chit, reurn false
  # Used to manually set kitty colors on shell start
  desired_theme_path=$1

  theme_colors=(
  background
  foreground
  color0
  # Other colors could be checked, but takes too much time
  )

  for color in "${theme_colors[@]}"; do
    desired_theme_color=$(eval grep -w "${color}" "${desired_theme_path}" | sed 's/ //g' | tr '[:upper:]' '[:lower:]')
    current_theme_color=$(eval kitty @ get-colors | grep -w "${color}" | sed 's/ //g'| tr '[:upper:]' '[:lower:]')
    if [[ "${desired_theme_color}" != "${current_theme_color}" ]]; then
      return 1 # False
    fi
  done

 return 0 # True
}


setiTermTheme() {
  scheme=$(getThemeVariable "${1}" "CHIT_ITERM_SCHEME")
  if [ -n "$TMUX" ]; then
    # If inside tmux, need to use the applescript to
    # Set all the colors
    osascript ${CONFIG_DIR}/iterm/change_iterm_session.scpt "${scheme}" &> /dev/null
  else
    # Otherwise, we can use the iTerm escape sequence
    eval echo -e "\033]1337;SetColors=preset=${scheme}\a"
  fi
}

setTerminalTheme() {
  # Set the colors of the current TTY and Terminal Emulator
  full_path_to_theme_conf="${1}"

  emulator=$(getTerminalEmulator)
  case $emulator in
    iTerm2)
      # This command sets the current TTY
      setiTermTheme "${full_path_to_theme_conf}"
    ;;
    kitty)
      kitty_theme_conf_path=$(getThemeVariable ${full_path_to_theme_conf} CHIT_KITTY_THEME_CONF_FILE_PATH)
      eval kitty @ set-colors "${kitty_theme_conf_path}"
    ;;
  esac
}

refreshKittyTheme() {
# For kitty, the kitty.conf file sources a file called "theme.conf"
# This file is a copy of the corresponding kitty theme file in chit
# This checks if the theme file is present, and if it has been applied.
# If not, the new theme conf file is copied to "theme.conf" to kitty to use at next load
# Also, the correct colors are then set for the current session
kitty_conf=$(getThemeVariable "${1}" "CHIT_KITTY_THEME_CONF_FILE_PATH")
if [ "${kitty_conf}" ]; then
  # The string is not empty
  eval ls ${kitty_conf} > /dev/null 2>&1
  if [[ $? == 0 ]]; then
    # There is a file with this path on disk
    if ! $(kittyThemeIsApplied "${kitty_conf}"); then
      # The colors from that file are not set for kitty currently
      # So...
      # Copy this theme file to the one sourced in kitty
      # This means it will be set properly by kitty on next start
      eval cp "${kitty_conf}" "${KITTY_THEME_CONF_PATH}"
      # Then, manually set the colors to the correct ones
      eval kitty @ set-colors "${kitty_conf}"
    fi
  fi
fi
}


##################
# CHIT FUNCTIONS #
##################
getFullPathToThemeFile() {
  # Given the name of a theme, construct the string for it's full path on disk
  # Then check if a files exists at that location
  # If yes, return it, otherwise return empty string
  theme_name="${1}"
  full_path_string="${CONFIG_DIR}/theme_definitions/${theme_name}.conf"
  if [[ -f "${full_path_string}" ]]; then
    echo "${full_path_string}"
  else
    echo ""
  fi
}

getThemeVariable() {
  # Given a variable, read the .conf file for the current theme
  # Return the value for the variable passed in
  full_path_to_theme_conf="${1}"
  variable_desired="${2}"

  value=""

  while read line
  do
      if echo $line | grep -F = &>/dev/null
      then
          if [ "${variable_desired}" = $(echo "$line" | cut -d '=' -f 1) ]
          then
              value=$(echo "$line" | cut -d '=' -f 2-)
          fi
      fi
  done < "${full_path_to_theme_conf}"

  echo "${value}"
}

exportVars() {
  full_path_to_theme_conf=${1}

  chit_vars=(
    # 'CHIT_ITERM_SCHEME'
    # 'CHIT_KITTY_THEME_CONF_FILE_PATH'
    # Debugging, shuold these just not be exported?
    # Vim plugin reads from the file on disk anyway
    # 'CHIT_VIM_COLORSCHEME'
    # 'CHIT_VIM_BEFORE'
    'BAT_THEME'
  )
  for i in "${chit_vars[@]}"; do
    echo "export ${i}=$(getThemeVariable ${full_path_to_theme_conf} ${i})"
  done
}


setup() {
  # Create the config files in ~/.config
  # Copy example theme files to this directory
  mkdir -p "${CONFIG_DIR}"
  touch "${CONFIG_DIR}"/current_theme
  setSavedSetting "${CONFIG_DIR}"/current_theme "dark"

  local theme_folder="${CONFIG_DIR}"/theme_definitions
  mkdir -p "${theme_folder}"
  cp -r /usr/local/etc/chit/example_theme_definitions/* "${theme_folder}"

  local kitty_theme_folder="${CONFIG_DIR}"/kitty_themes
  mkdir -p "${kitty_theme_folder}"
  cp -r /usr/local/etc/chit/kitty_themes/* "${kitty_theme_folder}"

  touch ${CONFIG_DIR}/tmux_theme.conf
  setSavedSetting "${CONFIG_DIR}"/tmux_theme.conf ""
}

shellInit() {
  # To be run on shell start (.bash_profile .zshrc etc.)
  # With the line: eval "$(chit shell-init)"
  #
  # Get the name of the currently set theme from the "current_theme" file
  # If there is not theme file with this name, throw an error
  # Otherwise, export variables and set terminal colors accordingly
  current_theme_name=$(getSavedSetting ${CONFIG_DIR}/current_theme)

  full_path_to_theme_conf=$(getFullPathToThemeFile "${current_theme_name}")
  if [ -z "${full_path_to_theme_conf}" ]; then
    # Echo-ing and echo, because this whole function is being eval-ed
    echo "echo chit unable to load! There is no theme with the name: ${current_theme_name}"
    exit 1
  else
    # export all of the env vars used by chit
    exportVars "${full_path_to_theme_conf}"
    # do any terminal-emulator-specific initialization tasks
    emulator=$(getTerminalEmulator)
    case $emulator in
      iTerm2)
        setiTermTheme "${full_path_to_theme_conf}"
      ;;
      kitty)
        refreshKittyTheme "${full_path_to_theme_conf}"
      ;;
    esac
  fi
}

listThemes() {
  # List all the themes
  # Each defined in a .conf file

  # The one-time setup process copies example theme files to the .conf dir,
  # If that hasn't run yet, do it now
  if [ ! -d "${CONFIG_DIR}" ]; then
    setup
  fi

  theme_definitions=($(ls ${CONFIG_DIR}/theme_definitions/*.conf 2> /dev/null))
  for i in "${theme_definitions[@]}"
  do
    echo $(basename "${i}" | sed "s/.conf//g")
  done
}

setThemeVariables() {
  # 1. Set the current theme, using setSavedSetting
  # 2. Use the theme's .conf file to set the theme of the current session
  theme_name="${1}"

  full_path_to_theme_conf=$(getFullPathToThemeFile "${theme_name}")
  # TODO: this is a copy-pasted block, can simplify?
  if [ -z "${full_path_to_theme_conf}" ]; then
    # Echo-ing and echo, because this whole function is being eval-ed
    echo "There is no theme with the name: ${theme_name}"
    exit 1
  else
    setSavedSetting "${CONFIG_DIR}"/current_theme "${theme_name}"
    setTerminalTheme "${full_path_to_theme_conf}"
    # echo "$(exportVars ${full_path_to_theme_conf})"
    eval "$(chit shell-init)"

    IFS_ORG=IFS
    IFS=';' read -r -a tmux_lines <<< "$(getThemeVariable ${full_path_to_theme_conf} TMUX_TPM_COMMANDS)"
    rm "${CONFIG_DIR}/tmux_theme.conf"
    touch "${CONFIG_DIR}/tmux_theme.conf"
    for line in "${tmux_lines[@]}"; do
      echo "${line}" >> "${CONFIG_DIR}/tmux_theme.conf"
    done
    IFS=IFS_ORG

    echo "Theme set to: ${theme_name}"
  fi
}

helpStringFunction() {
  echo "chit usage:"
  echo "  h|help:
      Show this help message"
  echo "  u|setup:
      Setup the necessary files in ~/.config"
  echo "  i|shell-init:
      Function to be called on shell init (.zshrc, .bash_profile, etc.)"
  echo "  l|list-themes:
      List available themes."
  echo "  s|set-theme theme_name:
      Set the current theme to theme_name."
  echo "  c|get-current-theme:
      Show the name of the current theme."
  echo "  v|get-theme-variable variable_name [theme_name]:
      Show value of variable_name in theme_name.
      If theme_name not supplied, use the current theme."
}

# Handle input to this script
case $1 in
  u|setup)
    setup
  ;;
  i|shell-init)
    shellInit
  ;;
  l|list-themes)
    listThemes
  ;;
  s|set-theme)
    setThemeVariables $2
  ;;
  c|get-current-theme)
    getSavedSetting ${CONFIG_DIR}/current_theme
  ;;
  g|get-theme-variable)
    theme=$(getSavedSetting ${CONFIG_DIR}/current_theme)
    if [ $# -eq 3 ]; then
      theme="${3}"
    fi
    full_path_to_theme_conf=$(getFullPathToThemeFile "${theme}")
    getThemeVariable $full_path_to_theme_conf $2
  ;;
  r|reload)
    echo "TODO"
  ;;
  h*|help)
    helpStringFunction
  ;;
  *)
    helpStringFunction
  ;;
esac
