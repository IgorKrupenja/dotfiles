#!/bin/bash

# Remap § key (paragraph, to the left of 1) to ` (backtick) key on macOS
# install.sh installs it to run at startup

hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000064,"HIDKeyboardModifierMappingDst":0x700000035}]}'
