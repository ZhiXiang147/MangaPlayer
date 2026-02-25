# Manga Player

一款用于 iPad 和 iPhone 的漫画自动播放应用，支持手势控制、文件管理和 Web 上传。

## 功能特性

### 核心功能
- 自动播放漫画，播放间隔可调（0.5秒到10秒）
- 手势控制播放（左滑/右滑跳转，上滑/下滑调速度，双击暂停）
- 全屏显示，支持横屏和竖屏

### 文件管理
- 创建和删除文件夹
- 导入和删除图片
- 支持所有 iOS 可解码的图片格式
- 缩略图预览

### Web 上传
- 局域网内通过浏览器上传文件
- 选择目标文件夹
- 支持批量上传

### 设置
- 播放间隔滑块调节
- Web 服务器启动/停止控制

## 技术栈

- Flutter 3.24.5
- Dart 3.5.4
- http_server（内嵌 Web 服务器）
- Provider（状态管理）

## 项目结构

```
lib/
├── main.dart
├── models/
│   ├── app_settings.dart
│   ├── folder.dart
│   └── manga_image.dart
├── services/
│   ├── file_service.dart
│   ├── image_player.dart
│   └── web_server.dart
├── screens/
│   ├── home_screen.dart
│   ├── folder_screen.dart
│   ├── player_screen.dart
│   └── settings_screen.dart
└── utils/
    └── constants.dart
```

## 快速开始

### 安装 Flutter（Linux）

```bash
cd ~/flutter-dev
wget https://mirrors.tuna.tsinghua.edu.cn/flutter/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz
export PATH="$PATH:$HOME/flutter-dev/flutter/bin"
```

### 克隆项目

```bash
git clone <your-repo-url>
cd manga_player
flutter pub get
```

### 运行（需要 macOS）

```bash
flutter run
```

## 构建和部署

由于 iOS 应用需要 macOS 环境编译，请参考 [DEPLOYMENT.md](DEPLOYMENT.md) 获取详细的部署指南。

## 使用说明

### 创建文件夹和导入图片

1. 创建文件夹：点击右下角 + 按钮
2. 导入图片：进入文件夹，点击右上角上传图标
3. 开始播放：点击任意图片，选择 "Play from here"

### 手势控制

- 左滑：上一张
- 右滑：下一张
- 上滑：增加播放速度
- 下滑：减少播放速度
- 双击：暂停/继续
- 长按：停止并返回

### Web 上传

1. 在应用中启动 Web 服务器
2. 在同一网络的浏览器中访问显示的 URL
3. 选择文件夹和图片，点击上传

## 常见问题

### Q: Web 服务器无法访问？
A: 确保设备和电脑在同一网络，防火墙未阻止 8080 端口

### Q: 应用闪退？
A: 在设置 > 通用 > VPN与设备管理中信任开发者

### Q: 图片无法加载？
A: 检查图片格式和文件权限

## 部署

详细的部署步骤和多种方案请查看 [DEPLOYMENT.md](DEPLOYMENT.md)，包括：
- 在线 macOS 服务编译（推荐）
- GitHub Actions 自动构建
- AltStore 侧载
- 签名和维护

## 许可证

仅供个人使用。
