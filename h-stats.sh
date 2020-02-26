#!/usr/bin/env bash
#######################
# Functions
#######################

get_cards_hashes(){
#Total hashrate 4057 MH/s
#        426 MH/s (10.5%): GeForce GTX 1080
#        406 MH/s (10.0%): GeForce GTX 1080
#        433 MH/s (10.7%): GeForce GTX 1080
#        417 MH/s (10.3%): GeForce GTX 1080
#        433 MH/s (10.7%): GeForce GTX 1080
#        394 MH/s ( 9.7%): P104-100
#        384 MH/s ( 9.5%): P104-100
#        389 MH/s ( 9.6%): P104-100
#        389 MH/s ( 9.6%): P104-100
#        386 MH/s ( 9.5%): P104-100


  hs=''
  khs=0
  local t_hs=-1
  local i=0;
  GPU_COUNT1=${GPU_COUNT}
  let "GPU_COUNT1+1"
  for (( i=1; i <= $GPU_COUNT1; i++ )); do
    fi2=$i'p'
#    t_hs=` cat /var/log/miner/tellor/tellor.log | grep -a "Total hashrate" | tail -n 1 | cut -d " " -f3 | awk '{ printf("%.3f", $1 + $2/1000) }'`
    t_hs=`cat $log_name | grep -a "MH/s (" | tail -n $GPU_COUNT1 | sed -n $fi2 | cut -d "M" -f1 | sed 's/ //g' | awk '{ printf("%.0f", $1*1000) }'`
    [[ ! -z $t_hs ]] && hs+=\"$t_hs\"" " && khs=`echo $khs $t_hs | awk '{ printf("%.6f", $1 + $2/1) }'`
  done
}

get_miner_uptime(){
  local a=0
  let a=`stat --format='%Y' $log_name`-`stat --format='%Y' $conf_name`
  echo $a
}

get_log_time_diff(){
  local a=0
  let a=`date +%s`-`stat --format='%Y' $log_name`
  echo $a
}

#######################
# MAIN script body
#######################

local log_dir=`dirname "$MINER_LOG_BASENAME"`
cd "$log_dir"
local log_name=$(ls -t --color=never | head -1)
log_name="/var/log/miner/toller/toller.log"
local ver=`miner_ver`
local conf_name="/hive/miners/custom/toller/config.json"
#"/hive/miners/custom/$MINER_NAME/config.txt"

local temp=$(jq '.temp' <<< $gpu_stats)
local fan=$(jq '.fan' <<< $gpu_stats)

[[ $cpu_indexes_array != '[]' ]] && #remove Internal Gpus
  temp=$(jq -c "del(.$cpu_indexes_array)" <<< $temp) &&
  fan=$(jq -c "del(.$cpu_indexes_array)" <<< $fan)

# Calc log freshness
local diffTime=$(get_log_time_diff)
local maxDelay=120

local algo="veltor"

GPU_COUNT=`echo $(gpu-detect NVIDIA) | awk '{ printf($1 + $2) }'`

# If log is fresh the calc miner stats or set to null if not
if [ "$diffTime" -lt "$maxDelay" ]; then
  get_cards_hashes # hashes array
  local hs_units='hs' # hashes utits
  local uptime=$(get_miner_uptime) # miner uptime

 # A/R shares by pool
  local ac=`cat $log_name  | grep -a "Submitting shares" | wc -l`

# make JSON
  stats=$(jq -nc \
        --argjson hs "`echo ${hs[@]} | tr " " "\n" | jq -cs '.'`" \
        --arg hs_units "$hs_units" \
        --argjson temp "$temp" \
        --argjson fan "$fan" \
        --arg uptime "$uptime" \
        --arg algo "$algo" \
        --arg ac "$ac" --arg rj "$rj" \
        --arg ver "$ver" \
        '{$hs, $hs_units, $temp, $fan, $uptime, ar: [$ac, $rj], $algo, $ver}')
else
  stats=""
  khs=0
fi

# debug output
##echo temp:  $temp
##echo fan:   $fan
#echo stats: $statsOD
#echo khs:   $khs
