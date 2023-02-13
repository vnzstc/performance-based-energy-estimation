#!/bin/bash 

SECONDS=0   # Reset $SECONDS; counting of seconds will (re)start from 0(-ish).
#while (( SECONDS < $1 )); do    # Loop until interval has elapsed.
  # ...

while :; do
  # Get the first line with aggregate of all CPUs 
  cpu_now=($(head -n1 /proc/stat)) 

  disk_time=`awk '/sda / { print $13 }' /proc/diskstats`
  disk_reqs=`awk '/sda / { print $4+$8 }' /proc/diskstats`

  # Get all columns but skip the first (which is the "cpu" string) 
  cpu_sum="${cpu_now[@]:1}" 

  # Replace the column seperator (space) with + 
  cpu_sum=$((${cpu_sum// /+})) 

  # Get the delta between two reads 
  cpu_delta=$((cpu_sum - cpu_last_sum)) 

  disk_delta=$((disk_time - disk_last))
  disk_reqs_delta=$((disk_reqs - disk_reqs_last))

  # Get the idle time Delta 
  cpu_idle=$((cpu_now[4]- cpu_last[4])) 

  # Calc time spent working 
  cpu_used=$((cpu_delta - cpu_idle)) 

  # Calc percentage 
  cpu_usage=`bc -l <<< "$cpu_used / $cpu_delta"` 
  disk_usage=`bc -l <<< "scale=5; $disk_delta/1000"`

  
  # Keep this as last for our next read 
  cpu_last=("${cpu_now[@]}") 

  disk_last=("${disk_time}")
  disk_reqs_last=("${disk_reqs}")

  cpu_last_sum=$cpu_sum 

  echo "$cpu_usage, $disk_usage, $disk_reqs_delta" 

  sleep 1 

done
