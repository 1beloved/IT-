
#!/usr/bin/env bash

# Linux 服务器自动巡检脚本
# 适用：CentOS Stream / RHEL 系 Linux

set -u

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$BASE_DIR/logs"
REPORT_DIR="$BASE_DIR/reports"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
REPORT="$REPORT_DIR/inspection_${TIMESTAMP}.txt"
LOG_FILE="$LOG_DIR/inspection.log"

# 巡检阈值，可按服务器实际情况调整
CPU_WARN=80
MEM_WARN=85
DISK_WARN=80

mkdir -p "$LOG_DIR" "$REPORT_DIR"

# 同时写入报告和运行日志
log() {
    local message="$1"
    printf '[%s] %s\n' "$(date '+%F %T')" "$message" \
        | tee -a "$REPORT" "$LOG_FILE"
}

# 统计正常项与异常项
PASS_COUNT=0
WARN_COUNT=0

check() {
    local name="$1"
    local status="$2"
    local detail="$3"

    if [[ "$status" == "OK" ]]; then
        ((PASS_COUNT += 1))
        log "[正常] $name：$detail"
    else
        ((WARN_COUNT += 1))
        log "[异常] $name：$detail"
    fi
}

log "========== 服务器巡检开始 =========="
log "主机名：$(hostname)"
log "系统运行时间：$(uptime -p 2>/dev/null || uptime)"

# 1. 系统负载
LOAD_1="$(awk '{print $1}' /proc/loadavg)"
CPU_COUNT="$(nproc 2>/dev/null || echo 1)"

if awk -v load="$LOAD_1" -v cpus="$CPU_COUNT" \
    'BEGIN {exit !(load > cpus)}'; then
    check "系统负载" "WARN" \
        "1分钟负载为 $LOAD_1，CPU逻辑核心数为 $CPU_COUNT"
else
    check "系统负载" "OK" \
        "1分钟负载为 $LOAD_1，CPU逻辑核心数为 $CPU_COUNT"
fi

# 2. CPU 使用率：读取 /proc/stat 前后两次采样
read -r _ U N S IDLE IOWAIT IRQ SOFTIRQ STEAL _ < /proc/stat
IDLE1=$((IDLE + IOWAIT))
TOTAL1=$((U + N + S + IDLE + IOWAIT + IRQ + SOFTIRQ + STEAL))

sleep 1

read -r _ U N S IDLE IOWAIT IRQ SOFTIRQ STEAL _ < /proc/stat
IDLE2=$((IDLE + IOWAIT))
TOTAL2=$((U + N + S + IDLE + IOWAIT + IRQ + SOFTIRQ + STEAL))

TOTAL_DELTA=$((TOTAL2 - TOTAL1))
IDLE_DELTA=$((IDLE2 - IDLE1))

if (( TOTAL_DELTA > 0 )); then
    CPU_USAGE=$(( (TOTAL_DELTA - IDLE_DELTA) * 100 / TOTAL_DELTA ))
    if (( CPU_USAGE >= CPU_WARN )); then
        check "CPU使用率" "WARN" "${CPU_USAGE}%"
    else
        check "CPU使用率" "OK" "${CPU_USAGE}%"
    fi
else
    check "CPU使用率" "WARN" "无法获取有效采样"
fi

# 3. 内存使用率
read -r MEM_TOTAL MEM_AVAILABLE < <(
    awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2}
         END {print t, a}' /proc/meminfo
)

if [[ "${MEM_TOTAL:-0}" -gt 0 ]]; then
    MEM_USAGE=$(( (MEM_TOTAL - MEM_AVAILABLE) * 100 / MEM_TOTAL ))
    if (( MEM_USAGE >= MEM_WARN )); then
        check "内存使用率" "WARN" "${MEM_USAGE}%"
    else
        check "内存使用率" "OK" "${MEM_USAGE}%"
    fi
else
    check "内存使用率" "WARN" "无法读取内存信息"
fi

# 4. 磁盘使用率：检查本地文件系统挂载点
while read -r USAGE MOUNT; do
    USAGE="${USAGE%\%}"
    if [[ "$USAGE" =~ ^[0-9]+$ ]]; then
        if (( USAGE >= DISK_WARN )); then
            check "磁盘 $MOUNT" "WARN" "使用率 ${USAGE}%"
        else
            check "磁盘 $MOUNT" "OK" "使用率 ${USAGE}%"
        fi
    fi
done < <(df -P -x tmpfs -x devtmpfs | awk 'NR>1 {print $5, $6}')

# 5. SSH 服务状态
if systemctl is-active --quiet sshd; then
    check "SSH服务" "OK" "sshd 正在运行"
else
    check "SSH服务" "WARN" "sshd 未运行或服务名称不同"
fi

# 6. 默认路由
if ip route show default | grep -q '^default'; then
    check "默认路由" "OK" "$(ip route show default | head -n 1)"
else
    check "默认路由" "WARN" "未发现默认路由"
fi

# 7. 端口监听：检查 SSH 常见端口 22
if ss -lntH | awk '{print $4}' | grep -Eq '(^|:)22$'; then
    check "SSH端口" "OK" "发现 22 端口监听"
else
    check "SSH端口" "WARN" "未发现 22 端口监听，请确认实际端口"
fi

# 8. DNS 解析
if getent hosts example.com >/dev/null 2>&1; then
    check "DNS解析" "OK" "example.com 解析成功"
else
    check "DNS解析" "WARN" "域名解析失败或外部网络不可用"
fi

# 9. 最近一小时的系统错误日志
if command -v journalctl >/dev/null 2>&1; then
    ERROR_COUNT="$(
        journalctl -p err --since '-1 hour' --no-pager -q 2>/dev/null \
            | grep -c . || true
    )"

    if (( ERROR_COUNT > 0 )); then
        check "系统错误日志" "WARN" \
            "最近一小时发现 ${ERROR_COUNT} 条错误级别日志"
    else
        check "系统错误日志" "OK" "未发现可读取的错误级别日志"
    fi
else
    check "系统错误日志" "WARN" "系统未提供 journalctl"
fi

log "========== 巡检结束 =========="
log "正常项：$PASS_COUNT，异常项：$WARN_COUNT"
log "报告路径：$REPORT"

