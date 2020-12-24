#!/usr/bin/env bash

# Homebrew build/install steps will make and populate this folder
CONFIG_DIR=${HOME}/.config/chit
# Must have a line in the kitty conf file to use this one
# TODO: Add readme step for this, and for other kitty seettings
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

  setting_file="${setting_file_name}"

  echo "${setting_value}" > "${setting_file}"
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
  # If the do not match the theme set by chit reurn false
  # Used to manually set kitty colors on shell start
  desired_theme_path=$1

  theme_colors=(
  background
  foreground
  color0
  # Other colors could be checked, but takes too much time
  )

  for color in "${theme_colors[@]}"; do
    desired_theme_color=$(grep -w "${color}" "${desired_theme_path}" | sed 's/ //g' | tr '[:upper:]' '[:lower:]')
    current_theme_color=$(kitty @ get-colors | grep -w "${color}" | sed 's/ //g'| tr '[:upper:]' '[:lower:]')
    if [[ "${desired_theme_color}" != "${current_theme_color}" ]]; then
      return 1 # False
    fi
  done

 return 0 # True
}


#########################
# CHIT HELPER FUNCTIONS #
#########################
setTerminalTheme() {
  # Set the colors of the current TTY and Terminal Emulator
  theme_name="${1}"

  emulator=$(getTerminalEmulator)
  case $emulator in
    kitty)
      # This command sets the current TTY
      if ! [ -z "${CHIT_KITTY_THEME_CONF_FILE_PATH}" ]; then
        eval kitty @ set-colors "${CHIT_KITTY_THEME_CONF_FILE_PATH}"
        # To make new windows take this effect, must restart kitty
        # Looking into hot reloading, see here https://github.com/kovidgoyal/kitty/issues/1292

        eval cp "${CHIT_KITTY_THEME_CONF_FILE_PATH}" "${KITTY_THEME_CONF_PATH}"

      fi
    ;;
    iTerm2)
      # This command sets the current TTY
      setiTermTheme "${CHIT_ITERM_SCHEME}"
    ;;
  esac
}

setiTermTheme() {
  scheme=$1

  if [ -n "$TMUX" ]; then
    # If inside tmux, need to use the applescript to
    # Set all the colors
    osascript ${CONFIG_DIR}/iterm/change_iterm_session.scpt "${scheme}" &> /dev/null
  else
    # Otherwise, we can use the iTerm escape sequence
      # TODO this check doesnt work... weird
    echo -e "\033]1337;SetColors=preset=${scheme}\a"
  fi
}

getThemeVariable() {
  # Given a variable, read the .conf file for the current theme
  # Return the value for the variable passed in
  current_theme_name="${1}"
  variable_desired="${2}"

  value=""

  current_theme_name=$(getSavedSetting "${CONFIG_DIR}"/current_theme)
  full_path_to_theme_conf="${CONFIG_DIR}/theme_definitions/${current_theme_name}.conf"

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
  current_theme_name=${1}

  # Export all the CHIT_ variables, so they're in the current env
  export CHIT_ITERM_SCHEME=$(getThemeVariable "${current_theme_name}" "iterm_scheme")
  export CHIT_KITTY_THEME_CONF_FILE_PATH=$(getThemeVariable "${current_theme_name}" "kitty_theme_path")
  export CHIT_VIM_COLORSCHEME=$(getThemeVariable "${current_theme_name}" "vim_colorscheme")
  export CHIT_BAT_THEME=$(getThemeVariable "${current_theme_name}" "bat_theme")
  export CHIT_VIM_BEFORE=$(getThemeVariable "${current_theme_name}" "vim_before")
}


#######################
# MAIN CHIT FUNCTIONS #
#######################
setup() {
  # Create the config files in ~/.config
  mkdir -p "${CONFIG_DIR}"
  touch "${CONFIG_DIR}"/current_theme
  echo "dark" > "${CONFIG_DIR}"/current_theme

  local theme_folder="${CONFIG_DIR}"/theme_definitions
  mkdir -p "${theme_folder}"
  cp -r /usr/local/etc/chit/example_theme_definitions/* "${theme_folder}"

  local kitty_theme_folder="${CONFIG_DIR}"/kitty_themes
  mkdir -p "${kitty_theme_folder}"
  cp -r /usr/local/etc/chit/kitty_themes/* "${kitty_theme_folder}"
}

shellInit() {
  # To be run on shell start (.bash_profile .zshrc etc.)
  current_theme_name=$(getSavedSetting "${CONFIG_DIR}"/current_theme)
  exportVars "${current_theme_name}"

  emulator=$(getTerminalEmulator)
  case $emulator in
    iTerm2)
      setiTermTheme "${CHIT_ITERM_SCHEME}"
    ;;
    kitty)
      # For kitty terminal, the kitty .conf file does not reload unless you restart the application
      # To get around that, this checks if the theme file changed, and manually applies it
      if ! [ -z "${CHIT_KITTY_THEME_CONF_FILE_PATH}" ]; then
        if ! $(kittyThemeIsApplied "${CHIT_KITTY_THEME_CONF_FILE_PATH}"); then
          kitty @ set-colors "${CHIT_KITTY_THEME_CONF_FILE_PATH}"
        fi
      fi
    ;;
  esac

  echo "chit has set the theme to ${current_theme_name}"
}

listThemes() {
  # List all the themes
  # Each defined in a .conf file

  # If the setup process has nott run, do it now
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
  # 2. Use the theme's .conf file to set all the env variables
  theme_name="${1}"

  setSavedSetting "${CONFIG_DIR}"/current_theme "${theme_name}"

  current_theme_name=$(getSavedSetting "${CONFIG_DIR}"/current_theme)
  exportVars "${current_theme_name}"

  setTerminalTheme "${theme_name}"
}

helpStringFunction() {
  echo "chit usage:"
  echo "  h|help:
      Show this help message"
  echo "  u|setup:
      setup the necessary files in ~/.config"
  echo "  i|shell-init:
      Function to be called on shell init (.zshrc, .bash_profile, etc.)"
  echo "  l|list-themes:
      List available themes"
  echo "  s|set-theme:
      Set the current theme"
  echo "  g|get-theme-variable:
      Given a variable, return it's value in the current theme"
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
    listThemes $2
  ;;
  s|set-theme)
    setThemeVariables $2
  ;;
  # TODO 'Create' command?
  # TODO is this needed? Just debugging?
  # -g|--get-theme-variable)
    # getThemeVariable $2
  # ;;
  h*|help)
    helpStringFunction
  ;;
  *)
    # TODO could put a message here about the option not being recognized
    helpStringFunction
  ;;
esac
