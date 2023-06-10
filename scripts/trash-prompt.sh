#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: trash-prompt.sh <files>"
  return 1
fi

echo "
  set ddr to display dialog \"Move this to trash?\" with title \"trash-prompt.sh\" buttons {\"No\", \"Yes\"} default button \"Yes\" cancel button \"No\"
  if button returned of ddr is \"Yes\" then
    do shell script \"/opt/homebrew/bin/trash $*\"
  end if
" | osascript -
