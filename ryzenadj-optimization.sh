#!/bin/bash
# Ryzen 5 5500U 动态温控脚本

TEMP_THRESHOLD=90
POWER_HIGH=25000
POWER_LOW=20000
COOL_DOWN=30
HYSTERESIS=2

THROTTLED=0
START_TIME=0

while true; do
    # 正确提取温度：取第三个字段（按 | 分割），去除空格
    TEMP_RAW=$(sudo ryzenadj -i 2>&1 | grep "THM VALUE CORE" | awk -F'|' '{print $3}' | tr -d ' ')
    if [ -z "$TEMP_RAW" ]; then
        echo "$(date) - [错误] 无法读取温度，请检查 sudo ryzenadj -i"
        sleep 5
        continue
    fi
    TEMP=$TEMP_RAW
    CURRENT_TIME=$(date +%s)

    if [ $THROTTLED -eq 1 ]; then
        ELAPSED=$((CURRENT_TIME - START_TIME))
        REMAINING=$((COOL_DOWN - ELAPSED))
        [ $REMAINING -lt 0 ] && REMAINING=0
        echo "$(date) - [冷却中] 温度 ${TEMP}°C，剩余 ${REMAINING} 秒"
        if [ $ELAPSED -ge $COOL_DOWN ]; then
            if awk "BEGIN {exit !($TEMP < $((TEMP_THRESHOLD - HYSTERESIS)))}"; then
                THROTTLED=0
                sudo ryzenadj --stapm-limit=$POWER_HIGH --fast-limit=$POWER_HIGH --slow-limit=$POWER_HIGH --tctl-temp=$TEMP_THRESHOLD
                echo "$(date) - [恢复] 冷却结束，温度 ${TEMP}°C，已恢复 25W"
            else
                START_TIME=$CURRENT_TIME
                echo "$(date) - [等待] 冷却结束但温度 ${TEMP}°C 仍偏高，继续冷却"
            fi
        fi
    else
        echo "$(date) - [正常] 温度 ${TEMP}°C"
        if awk "BEGIN {exit !($TEMP >= $TEMP_THRESHOLD)}"; then
            THROTTLED=1
            START_TIME=$CURRENT_TIME
            sudo ryzenadj --stapm-limit=$POWER_LOW --fast-limit=$POWER_LOW --slow-limit=$POWER_LOW --tctl-temp=$TEMP_THRESHOLD
            echo "$(date) - [降频] 温度 ${TEMP}°C 达到阈值，限制为 20W，持续 ${COOL_DOWN} 秒"
        fi
    fi
    sleep 5
done
