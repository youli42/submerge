#!/bin/bash
# podman-compose 1.3.0 不透传 compose 的 networks.<n>.interface_name，netns 网卡退化为随机顺序 eth0/eth1。
# 上游语义要求 egress=eth0、gateway-lan=lan0（面板默认 outboundInterface=eth0、nft 规则引用 lan0）。
# down/rename/up 会冲掉 default 路由，因此本脚本同时幂等地恢复默认路由（netavark 网关恒为该 /24 的 .1）。
CID=$(podman ps -q -f name=^submerge_submerge-network_1$ | head -1)
[ -z "$CID" ] && exit 0
PID=$(podman inspect -f "{{.State.Pid}}" "$CID")
[ -z "$PID" ] || [ "$PID" = "0" ] && exit 0
NS="nsenter -t $PID -n"
LAN_IF=$($NS ip -o -4 addr | awk '$4 ~ /^10\.199\.77\./ {print $2}' | head -1)
if [ -n "$LAN_IF" ] && [ "$LAN_IF" != "lan0" ]; then
  $NS ip link set "$LAN_IF" down && $NS ip link set "$LAN_IF" name lan0 && $NS ip link set lan0 up
  logger -t fix-ifnames "renamed $LAN_IF -> lan0"
fi
DEF_IF=$($NS ip -o route | awk '/^default / {print $5}' | head -1)
if [ -n "$DEF_IF" ] && [ "$DEF_IF" != "eth0" ]; then
  $NS ip link set "$DEF_IF" down && $NS ip link set "$DEF_IF" name eth0 && $NS ip link set eth0 up
  logger -t fix-ifnames "renamed $DEF_IF -> eth0"
fi
if ! $NS ip -o route | grep -q "^default"; then
  NET=$($NS ip -o -4 addr | awk '$2=="eth0" {print $4}' | head -1)
  [ -n "$NET" ] || exit 0
  GW=$(echo "${NET%/*}" | cut -d. -f1-3).1
  $NS ip route add default via "$GW" dev eth0 metric 100
  logger -t fix-ifnames "default route restored via $GW dev eth0"
fi
exit 0
