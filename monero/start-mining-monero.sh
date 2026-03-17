#!/bin/bash

# -------------------------------
# Detect available CPU threads
# -------------------------------

get_threads() {
    # cgroup v2 (modern systems, RunPod, Docker)
    if [ -f /sys/fs/cgroup/cpu.max ]; then
        read quota period < /sys/fs/cgroup/cpu.max

        if [ "$quota" != "max" ]; then
            echo $((quota / period))
            return
        fi
    fi

    # cgroup v1 (older systems)
    if [ -f /sys/fs/cgroup/cpu/cpu.cfs_quota_us ]; then
        quota=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
        period=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us)

        if [ "$quota" -gt 0 ]; then
            echo $((quota / period))
            return
        fi
    fi

    # cpuset restriction
    if [ -f /sys/fs/cgroup/cpuset.cpus ]; then
        cpus=$(cat /sys/fs/cgroup/cpuset.cpus)
        count=0

        IFS=',' read -ra ranges <<< "$cpus"
        for r in "${ranges[@]}"; do
            if [[ "$r" == *-* ]]; then
                start=${r%-*}
                end=${r#*-}
                count=$((count + end - start + 1))
            else
                count=$((count + 1))
            fi
        done

        echo $count
        return
    fi

    # fallback (bare metal)
    nproc
}

THREADS=$(get_threads)

# Safety: minimum 1 thread
if [ "$THREADS" -lt 1 ]; then
    THREADS=1
fi

echo "Detected threads: $THREADS"

# -------------------------------
# Launch miner
# -------------------------------

exec /home/sdamours/miners-public/xmrig \
-o ca.monero.herominers.com:1111 \
-u 49yMArqpSkG58sYr6RHrcTKqJU1o7BcEmdsGfdsjBTMAcHXHDBsevvmCF8RtTuYAVo2G7mvQXHh5Q3i7gNMs7vNpTEPM5fo.$(hostname) \
-a rx/0 \
-k \
-t $THREADS \
--randomx-1gb-pages