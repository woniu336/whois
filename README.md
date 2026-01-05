## 一键部署脚本

提醒：开放8080端口

```
curl -fsSL https://raw.githubusercontent.com/woniu336/whois/main/install.sh | sudo bash
```

通知说明： `剩余天数`精准匹配`提醒天数`就会触发通知，默认在凌晨两点通知(可在检测频率)设置

## 部署文件清单

部署时需要以下文件/目录：

```

# 必需的配置和静态文件
config/               # 配置文件目录
  └── config.yaml     # 系统配置文件
web/                  # 前端静态文件目录
  └── dist/           # 编译后的前端文件
      ├── index.html  # 主页面
      ├── css/        # 样式文件
      │   └── style.css
      └── js/         # JavaScript文件
          └── app.js
```

## Linux服务器部署（Debian/Ubuntu/CentOS等）

### 1. 上传文件
```bash
# 将以下文件上传到服务器
domain-monitor-linux-amd64
config/
web/
```

### 2. 设置执行权限
```bash
chmod +x domain-monitor-linux-amd64
```

### 3. 修改配置文件
```bash
vi config/config.yaml
# 配置数据库路径、端口等信息
```

### 4. 启动服务
```bash
# 方式1：前台运行（测试用）
./domain-monitor-linux-amd64

# 方式2：后台运行
nohup ./domain-monitor-linux-amd64 > logs.txt 2>&1 &

# 方式3：使用systemd守护进程（推荐）
# 创建服务文件 /etc/systemd/system/domain-monitor.service
sudo systemctl start domain-monitor
sudo systemctl enable domain-monitor  # 开机自启
```

### 5. 检查运行状态
```bash
# 查看进程
ps aux | grep domain-monitor

# 查看端口
netstat -tlnp | grep 8080

# 查看日志
tail -f logs.txt
```



## 访问系统

无论使用哪个平台，启动后访问：
```
浏览器打开：http://localhost:8080
默认账户：admin
默认密码：admin123
```

## 功能特性

- ✅ 域名WHOIS查询和到期监控
- ✅ 多渠道通知（邮件、Telegram、钉钉）
- ✅ JWT身份认证
- ✅ 密码加密存储（bcrypt）
- ✅ 自动定时检测
- ✅ Web管理界面

## 通知配置说明


### 邮件通知

支持所有标准SMTP服务器，已针对QQ邮箱优化。

### 钉钉通知

支持加签安全设置，可选配置secret密钥。

## systemd服务配置（Linux推荐）

创建服务文件 `/etc/systemd/system/domain-monitor.service`：

```ini
[Unit]
Description=Domain Expiry Monitor Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/domain-monitor
ExecStart=/opt/domain-monitor/domain-monitor-linux-amd64
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

启动服务：
```bash
sudo systemctl daemon-reload
sudo systemctl start domain-monitor
sudo systemctl enable domain-monitor  # 开机自启
sudo systemctl status domain-monitor  # 查看状态
```

## 技术栈

- 后端：Go + Gin + GORM
- 数据库：SQLite（纯Go实现）
- 前端：原生JavaScript
- 认证：JWT + bcrypt

## 版本信息

- 编译时间：2026-01-05
- Go版本：go1.21+
- 平台支持：
  - Linux amd64（Debian/Ubuntu/CentOS等）


## 文件说明

- `domain-monitor-linux-amd64`：Linux 64位静态编译二进制文件，无依赖


## 注意事项

1. 数据库文件会自动在程序首次运行时创建
2. 默认数据库路径：`./data/domain-monitor.db`
3. 日志输出到标准输出（stdout）
4. Telegram api 是否联通
5. 定时任务默认每天凌晨2点执行

## 问题排查

1. **无法访问Web界面**
   - 检查端口是否被占用
   - 检查防火墙设置

2. **Telegram通知失败**
   - 确认SOCKS5代理（127.0.0.1:7890）是否运行
   - 检查Bot Token和Chat ID是否正确

3. **邮件通知失败**
   - 检查SMTP配置是否正确
   - 确认邮箱授权码（非登录密码）

