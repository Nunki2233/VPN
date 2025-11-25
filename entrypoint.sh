#!/bin/sh
set -eu

# 允许通过环境变量 PORT 指定端口（Railway 会注入 PORT）
# 若未提供 PORT，则回退到 2333
LISTEN_PORT="${PORT:-2333}"

# Domain/Password 等从环境变量读取（如果你已在 Railway Variables 设置了）
DOMAIN="${Domain:-}"
PASSWORD="${Password:-ivmvf8654}"

# 假设仓库原来生成了 /etc/shadowsocks-libev/config.json
# 我们在启动前用 sed 修改监听地址和端口，确保对外可达
# 将 "127.0.0.1" 替换为 "0.0.0.0"
if [ -f /etc/shadowsocks-libev/config.json ]; then
  # 替换 server 地址为 0.0.0.0
  sed -i 's/"server"[[:space:]]*:[[:space:]]*"127.0.0.1"/"server":"0.0.0.0"/g' /etc/shadowsocks-libev/config.json

  # 用 LISTEN_PORT 替换 server_port 字段（处理可能出现的带引号或不带引号）
  # 先尝试替换字符串值
  sed -i "s/\"server_port\"[[:space:]]*:[[:space:]]*\"[0-9]*\"/\"server_port\":\"${LISTEN_PORT}\"/g" /etc/shadowsocks-libev/config.json
  # 再尝试替换数字值
  sed -i "s/\"server_port\"[[:space:]]*:[[:space:]]*[0-9]*/\"server_port\":\"${LISTEN_PORT}\"/g" /etc/shadowsocks-libev/config.json

  # 如果 config.json 里也包含 password、plugin_opts 等，可以按需替换：
  sed -i "s/\"password\"[[:space:]]*:[[:space:]]*\"[^\"]*\"/\"password\":\"${PASSWORD}\"/g" /etc/shadowsocks-libev/config.json
fi

# 如果有 v2 配置文件（v2 或 v2ray 配置），也替换绑定地址与端口
# 假设 V2 配置保存在 /etc/v2ray/config.json（请根据实际路径调整）
if [ -f /etc/v2ray/config.json ]; then
  sed -i 's/"listen"[[:space:]]*:[[:space:]]*"127.0.0.1"/"listen":"0.0.0.0"/g' /etc/v2ray/config.json || true
  sed -i "s/\"port\"[[:space:]]*:[[:space:]]*[0-9]*/\"port\":${LISTEN_PORT}/g" /etc/v2ray/config.json || true
  sed -i "s/\"port\"[[:space:]]*:[[:space:]]*\"[0-9]*\"/\"port\":${LISTEN_PORT}/g" /etc/v2ray/config.json || true
fi

# 确保 entrypoint 可执行（如果在 Dockerfile 中未设置）
chmod +x /entrypoint.sh || true

# 最后执行原有的启动命令（这里用 exec 保持 PID 1）
# 如果你原来直接调用了 v2ray 或 ss-server，请保留原有命令
# 下面是示例：启动 shadowsocks-libev（请替换为你仓库实际的命令）
exec /usr/bin/supervisord -n
