#!/bin/bash

#################################################################################
# Dark: Switch between system dark and light modes on macOS
# and manually switch between dark and light themes in some apps.
#################################################################################

# prevent running not on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "Dark mode script only supports macOS, exiting."
  exit
fi

################################# macOS dark mode

osascript -e '
	tell application "System Events"
		tell appearance preferences
			set dark mode to not dark mode
		end tell
	end tell
'

################################# variable for other apps

# define variable if changing light -> dark
# 2>/dev/null to suppress error if changing dark -> light
if [[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == "Dark" ]]; then
  set_dark=true
fi

################################# Marta

conf=$HOME/Library/Application\ Support/org.yanex.marta/conf.marco

if [ "$set_dark" = true ]; then
  sed -i '' -e 's/theme "Classic"/theme "Igor"/g' "$conf"
else
  sed -i '' -e 's/theme "Igor"/theme "Classic"/g' "$conf"
fi

################################# PDF Expert

if [[ $(pgrep "PDF Expert") ]]; then
  if [ "$set_dark" = true ]; then
    osascript -e '
    		tell application "PDF Expert" to activate
				tell application "System Events"
					keystroke "n" using {option down, command down}
				end tell
			'
  else
    osascript -e '
    		tell application "PDF Expert" to activate
				tell application "System Events"
					keystroke "z" using {option down, command down}
				end tell
			'
  fi
fi

################################# Cursor

conf=$HOME/Library/Application\ Support/Cursor/User/settings.json

light_values=(
  # To do highlighting
  '"color": "#A74047"'
  '"backgroundColor": "#A7404715"'
  '"overviewRulerColor": "#A74047"'
  # Git graph
  '#D73A4A'
  '#28A745'
  '#DCAB07'
  '#0366D6'
  '#5B32A3'
  '#1C7C82'
)
dark_values=(
  # To do highlighting
  '"color": "#b48ead"'
  '"backgroundColor": "#b48ead30"'
  '"overviewRulerColor": "#b48ead"'
  # Git graph
  '#5E81AC'
  '#88C0D0'
  '#BF616A'
  '#A3BE8C'
  '#EBCB8B'
  '#B48EAD'
)

for i in "${!light_values[@]}"; do
  if [ "$set_dark" = true ]; then
    # light ->  dark
    sed -i '' "s/${light_values[i]}/${dark_values[i]}/g" "$conf"
  else
    # dark -> light
    sed -i '' "s/${dark_values[i]}/${light_values[i]}/g" "$conf"
  fi
done

################################# Switch back to iTerm

osascript -e 'tell application "iTerm" to activate'
ø
