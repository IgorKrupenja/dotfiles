#!/bin/bash

##############################################################################
# Status: script to show different status info about hardware/software
##############################################################################

if [[ "$OSTYPE" != "darwin"* ]]; then
  # prevemt running not on macOS
  echo "Status script only supports macOS, exiting."
  exit
fi

# return time difference between two times in human-readable format
get_time_difference() {
  time_ago=$(($1 - $2))
  awk -v time=$time_ago 'BEGIN { seconds = time % 60; minutes = int(time / 60 % 60);
        hours = int(time / 60 / 60 % 24); days = int(time / 60 / 60 / 24);
        printf("%.0fd %.0fh %.0fm %.0fs", days, hours, minutes, seconds); exit }'
}

# get current time
unix_time=$(date +%s)

# build uptime string
boot_time=$(sysctl -n kern.boottime | awk '{print $4}' | sed 's/,//g')
uptime=$(get_time_difference "$unix_time" "$boot_time")

# build battery info strings
time_batt_change=$(date -jf%T $(pmset -g log | grep -w 'Using Batt' | tail -1 | cut -d ' ' -f 2) +%s)
batt_time=$(get_time_difference "$unix_time" "$time_batt_change")
batt_info=$(pmset -g ps | grep Internal | sed $'s/\t/ /g')
batt_perc=$(echo "$batt_info" | cut -d ' ' -f 4-5 | sed 's/;//2')
batt_remain=$(echo "$batt_info" | cut -d ' ' -f 6-7 | sed 's/:/h /g')
batt_cycles=$(system_profiler SPPowerDataType 2>/dev/null | grep "Cycle Count" | awk '{print $3}')

# build CPU/RAM info helper string
top_info="$(top | head -n 7)"

# build RAM Info
blocks_free=$(vm_stat | grep free | awk '{ print $3 }' | sed 's/\.//')
blocks_inactive=$(vm_stat | grep inactive | awk '{ print $3 }' | sed 's/\.//')
blocks_speculative=$(vm_stat | grep speculative | awk '{ print $3 }' | sed 's/\.//')
mem_free=$((($blocks_free + $blocks_speculative) * 4096 / 1048576))
mem_inactive=$(($blocks_inactive * 4096 / 1048576))
mem_total_free=$(($mem_free + $mem_inactive))
mem_total=$(($(sysctl -n hw.memsize) / (1024 ** 3)))

# show status data
echo "Date        : $(date -R) $(ls -l /etc/localtime | /usr/bin/cut -d '/' -f 8,9)"
echo "Uptime      : $uptime"
echo "OS          : macOS $(sw_vers -productVersion)"
echo "Kernel      : $(uname -s -r)"
echo "Model       : MacBook Pro 16-inch 2019"
echo "CPU         : $(echo "$top_info" | grep -E "^CPU" | sed -n 's/CPU usage: //p')- $(sysctl -n machdep.cpu.brand_string)"
echo "Memory      : ${mem_total}GB total; ${mem_free}MB free, ${mem_inactive}MB inactive, ${mem_total_free}MB total free"
echo "Swap        : $(sysctl vm.swapusage | sed -n 's/vm.swapusage:\ //p')"
echo "Battery     : $batt_perc for $batt_time, $batt_remain; cycle count $batt_cycles"
echo "Hostname    : $(uname -n)"
echo "WiFI SSID   : $(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk -F' SSID: ' '/ SSID: / {print $2}' | xargs)"
echo "Internal IP : $(ipconfig getifaddr en0)"
echo "External IP : $(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F '"' '{ print $2}')"
