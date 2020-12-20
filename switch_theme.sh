#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

KITTY_THEME_CONF_PATH="${HOME}/.config/kitty/theme.conf"

source "${SCRIPT_DIR}"/saved_settings.sh
source "${SCRIPT_DIR}"/themeIsApplied.sh

listThemes() {
  # List all the theme options
  # Each defined in a .conf file
  theme_definitions=($(ls ${SCRIPT_DIR}/theme_definitions/))
  for i in "${theme_definitions[@]}"
  do
    echo "${i}"
  done
}


getTerminalEmulator() {
  # Name of the current terminal emulator application
  terminal_emulator=$(osascript -e 'tell application "System Events"' \
                                -e 'set frontApp to name of first application process whose frontmost is true' \
                                -e 'end tell')
  echo "${terminal_emulator}"
}


setTerminalTheme() {
  # Set the colors of the current TTY and Terminal Emulator
  theme_name="${1}"

  emulator=$(getTerminalEmulator)
  case $emulator in
    kitty)
      # This command sets the current TTY
      if ! [ -z "${CHIT_KITTY_THEME_CONF_FILE_PATH}" ]; then
        kitty @ set-colors  "${CHIT_KITTY_THEME_CONF_FILE_PATH}"
        # To make new windows take this effect, must restart kitty
        # Looking into hot reloading, see here https://github.com/kovidgoyal/kitty/issues/1292
        cp "${CHIT_KITTY_THEME_CONF_FILE_PATH}" "${KITTY_THEME_CONF_PATH}"
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
    osascript ${SCRIPT_DIR}/iterm/change_iterm_session.scpt "${scheme}" &> /dev/null
  else
    # Otherwise, we can use the iTerm escape sequence
      # TODO this check doesnt work... weird
    echo -e "\033]1337;SetColors=preset=${scheme}\a"
  fi
}


setThemeVariables() {
  # 1. Set the current theme, using set_saved_setting
  # 2. Use the theme's .conf file to set all the env variables
  theme_name="${1}"

  set_saved_setting "${SCRIPT_DIR}"/current_theme.txt "${theme_name}"

  exportVars

  setTerminalTheme "${theme_name}"
}

exportVars() {
  export CHIT_ITERM_SCHEME=$(getThemeVariable "iterm_scheme")
  export CHIT_KITTY_THEME_CONF_FILE_PATH=$(getThemeVariable "kitty_theme_path")
  export CHIT_VIM_COLORSCHEME=$(getThemeVariable "vim_colorscheme")
  export CHIT_BAT_THEME=$(getThemeVariable "bat_theme")
  export CHIT_VIM_BEFORE=$(getThemeVariable "vim_before")
}


getThemeVariable() {
  # Given a variable, read the .conf file for the current theme
  # Return the value for the variable passed in
  variable_desired="${1}"

  value=""

  current_theme_name=$(get_saved_setting "${SCRIPT_DIR}"/current_theme.txt)
  full_path_to_theme_conf="${SCRIPT_DIR}/theme_definitions/${current_theme_name}.conf"

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

shellInit() {
  # To be run on shell start (.bash_profile .zshrc etc.)
  exportVars

  emulator=$(getTerminalEmulator)
  case $emulator in
    iTerm2)
      setiTermTheme "${CHIT_ITERM_SCHEME}"
    ;;
    kitty)
      # For kitty terminal, the kitty .conf file does not reload unless you restart the application
      # To get around that, this checks if the theme file changed, and manually applies it
      if ! [ -z "${CHIT_KITTY_THEME_CONF_FILE_PATH}" ]; then
        echo "it's not empty"
        echo "${CHIT_KITTY_THEME_CONF_FILE_PATH}"
        if ! $(themeIsApplied "${CHIT_KITTY_THEME_CONF_FILE_PATH}"); then
          kitty @ set-colors "${CHIT_KITTY_THEME_CONF_FILE_PATH}"
        fi
      fi
    ;;
  esac
}


# Handle input to this script
case $1 in
  -i|--shell-init)
    shellInit
  ;;
  -l|--list-themes)
    listThemes $2
  ;;

  -s|--set-themes)
    setThemeVariables $2
  ;;

  -g|--get-theme-variable)
    getThemeVariable $2
  ;;
esac
