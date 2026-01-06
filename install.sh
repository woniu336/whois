#!/bin/bash
set -e

INSTALL_DIR="/opt/domain-monitor"
VERSION="v2.0.0"
RELEASE_URL="https://github.com/woniu336/whois/releases/download/$VERSION"
BINARY_URL="$RELEASE_URL/domain-monitor-linux-amd64"
WEB_CONFIG_URL="$RELEASE_URL/web-config.tar.gz"

echo "==> 开始安装域名监控系统..."

# 创建安装目录
echo "==> 创建安装目录: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# 下载二进制文件
echo "==> 下载二进制文件..."
curl -L -o domain-monitor "$BINARY_URL"
chmod +x domain-monitor

# 下载配置文件和 Web 静态资源
echo "==> 下载配置文件和静态资源..."
curl -L -o web-config.tar.gz "$WEB_CONFIG_URL"
tar -xzf web-config.tar.gz
rm -f web-config.tar.gz

# ===== 关键修复点：配置文件兜底生成 =====
echo "==> 检查配置文件..."

mkdir -p config

if [ ! -f config/config.yaml ]; then
    if [ -f config/config.yaml.example ]; then
        cp config/config.yaml.example config/config.yaml
        echo "==> 已自动生成 config/config.yaml"
    else
        echo "❌ 缺少 config.yaml.example，无法生成配置文件"
        exit 1
    fi
fi

# 启动前强校验，防止 systemd 无限重启
if [ ! -s config/config.yaml ]; then
    echo "❌ 配置文件为空: $INSTALL_DIR/config/config.yaml"
    exit 1
fi

# 创建 systemd 服务
echo "==> 创建 systemd 服务..."
cat > /etc/systemd/system/domain-monitor.service <<EOF
[Unit]
Description=Domain Expiry Monitor Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/domain-monitor
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd
systemctl daemon-reload

# 启动并设置开机自启
echo "==> 启动服务..."
systemctl enable domain-monitor
systemctl start domain-monitor

# 检查服务状态
sleep 2
if systemctl is-active --quiet domain-monitor; then
    echo ""
    echo "✅ 安装成功！"
    echo ""
    echo "服务状态: $(systemctl is-active domain-monitor)"
    echo "访问地址: http://$(hostname -I | awk '{print $1}'):8080"
    echo ""
    echo "常用命令:"
    echo "  查看状态: systemctl status domain-monitor"
    echo "  查看日志: journalctl -u domain-monitor -f"
    echo "  重启服务: systemctl restart domain-monitor"
    echo "  停止服务: systemctl stop domain-monitor"
    echo ""
else
    echo "❌ 服务启动失败，请检查日志:"
    journalctl -u domain-monitor -n 50 --no-pager
    exit 1
fi
