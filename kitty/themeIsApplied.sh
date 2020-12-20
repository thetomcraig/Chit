themeIsApplied() {
  desiredThemePath=$1

  themeColors=(
  background
  foreground
  color0
  # color1
  # color2
  # color3
  # color4
  # color5
  # color6
  # color7
  # color8
  # color9
  # color10
  # color11
  # color12
  # color13
  # color14
  # color15
  )

  for color in "${themeColors[@]}"; do
    desiredThemeColor=$(grep -w "${color}" "${desiredThemePath}" | sed 's/ //g' | tr '[:upper:]' '[:lower:]')
    currentThemeColor=$(kitty @ get-colors | grep -w "${color}" | sed 's/ //g'| tr '[:upper:]' '[:lower:]')
    if [[ "${desiredThemeColor}" != "${currentThemeColor}" ]]; then
      return 1 # False
    fi
  done

 return 0 # True
}
