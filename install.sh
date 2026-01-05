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
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# 下载二进制文件
echo "==> 下载二进制文件..."
curl -L -o domain-monitor $BINARY_URL
chmod +x domain-monitor

# 下载配置文件和Web文件
echo "==> 下载配置文件和静态资源..."
curl -L -o web-config.tar.gz $WEB_CONFIG_URL
tar -xzf web-config.tar.gz
rm -f web-config.tar.gz

# 复制配置示例
if [ ! -f config/config.yaml ]; then
    echo "==> 创建配置文件..."
    cp config/config.yaml.example config/config.yaml
    echo "⚠️  请编辑配置文件: $INSTALL_DIR/config/config.yaml"
fi

# 创建systemd服务
echo "==> 创建systemd服务..."
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

# 重新加载systemd
systemctl daemon-reload

# 启动服务
echo "==> 启动服务..."
systemctl start domain-monitor
systemctl enable domain-monitor

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
    echo "  修改配置: vi $INSTALL_DIR/config/config.yaml"
    echo ""
    echo "⚠️  首次使用请编辑配置文件后重启服务"
else
    echo "❌ 服务启动失败，请检查日志: journalctl -u domain-monitor -xe"
    exit 1
fi
