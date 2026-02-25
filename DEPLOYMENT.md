# Manga Player - iOS 部署指南

## 概述
由于您在 Linux 环境下开发，而 iOS 应用需要 macOS 环境编译，本指南提供多种在无需本地 Mac 的情况下编译并部署应用到 iPhone/iPad 的方案。

## 方案选择

### 推荐方案：使用在线 macOS 服务（MacStadium 或 MacInCloud）
**最适合个人开发者，简单易用**

### 备选方案：
1. **GitHub Actions 自动构建** - 免费但需要配置
2. **Codemagic CI/CD** - 免费额度有限
3. **借用朋友的 Mac** - 最简单但需要他人帮助

---

## 方案 A：使用在线 macOS 服务（推荐）

### 1. 选择服务提供商

**MacInCloud** (macincloud.com)
- 按小时计费，约 $0.50-1.00/小时
- 提供预配置的 macOS 环境
- 支持远程桌面访问
- 推荐：Mac Studio 或 Mac mini 配置

**MacStadium** (macstadium.com)
- 按月计费，约 $79-149/月
- 适合长期使用
- 提供 CI/CD 集成

**Setup-X** (setup-x.com)
- 较便宜，约 $0.20-0.40/小时
- 基础配置即可

### 2. 准备工作

**在 Linux 上：**
```bash
# 1. 提交代码到 Git
cd /home/eyecloud/manga_player
git init
git add .
git commit -m "Initial commit"
git remote add origin <你的GitHub仓库地址>
git push -u origin main
```

**创建 GitHub 仓库：**
1. 访问 https://github.com/new
2. 创建新仓库 "manga-player"
3. 不要添加 README（我们已经有代码了）
4. 获取仓库 URL

### 3. 使用 MacInCloud 编译

#### 步骤 3.1：注册和预订
1. 访问 https://macincloud.com
2. 注册账号
3. 选择一个 Mac 实例（建议 macOS 14+，Xcode 15+）
4. 预订 1-2 小时（足够编译）

#### 步骤 3.2：连接到 Mac
1. 收到连接信息后，通过 Microsoft Remote Desktop 或其他 RDP 客户端连接
2. 登录到 macOS

#### 步骤 3.3：在 Mac 上安装 Flutter
```bash
# 安装 Homebrew（如果没有）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 Flutter
brew install --cask flutter

# 验证安装
flutter doctor
```

#### 步骤 3.4：克隆项目
```bash
cd ~/Desktop
git clone <你的GitHub仓库URL>
cd manga_player
```

####。步骤 3.5：安装依赖
```bash
flutter pub get
```

#### 步骤 3.6：编译 iOS 应用
```bash
# 在 Mac 上，这会使用 Xcode 编译
flutter build ios --release
```

编译完成后，IPA 文件位置：
```
~/Desktop/manga_player/build/ios/ipa/manga_player.ipa
```

#### 步骤 3.7：下载 IPA 文件
1. 将 IPA 文件传输到你的云存储（如 Google Drive）
2. 或通过浏览器下载到本地

---

## 方案 B：使用 GitHub Actions 自动构建（免费）

### 1. 创建 GitHub 仓库
（同方案 A 步骤 2）

### 2. 配置 GitHub Actions

创建文件 `.github/workflows/build-ios.yml`：
```yaml
name: Build iOS

on:
  workflow_dispatch:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.24.5'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Build iOS (No Codesign)
      run: |
        flutter build ios --release --no-codesign
    
    - name: Archive
      run: |
        cd build/ios/iphoneos
        zip -r ../../../manga_player.zip Runner.app
        cd ../..
        mkdir -p ipa
        mv ../manga_player.zip ipa/manga_player.zip
    
    - name: Upload Artifact
      uses: actions/upload-artifact@v4
      with:
        name: manga-ios-build
        path: build/ios/ipa/manga_player.zip
        retention-days: 30
```

### 3. 触发构建
1. 推送代码到 GitHub：
```bash
git push origin main
```

2. 或手动触发：
   - 访问 GitHub 仓库
   - 点击 "Actions" 标签页
   - 选择 "Build iOS" workflow
   - 点击 "Run workflow"

### 4. 下载构建产物
1. 等待构建完成（约 10-15 分钟）
2. 在 Actions 页面下载 `manga-ios-build` artifact
3. 解压得到 `Runner.app`

### 5. 创建 IPA
由于 GitHub Actions 默认没有代码签名，需要手动打包：
- 在实际 Mac 上，这需要开发者账号
- 对于免费侧载，我们改用方案 C（Codemagic）

---

## 方案 C：使用 Codemagic（推荐用于侧载）

### 1. 注册 Codemagic
1. 访问 https://codemagic.io
2. 使用 GitHub 账号登录
3. 选择 "manga-player" 仓库

### 2. 配置项目
1. Codemagic 会自动检测 Flutter 项目
2. 选择 "iOS" 平台
3. 点击 "Start building"

### 3. 配置构建设置
在 `codemagic.yaml` 文件中配置：
```yaml
workflows:
  ios-workflow:
    name: iOS Workflow
    environment:
      xcode: 15.0
      cocoapods: default
    triggering:
      events:
        - push
      branch_patterns:
        - pattern: main
    scripts:
      - name: Build iOS
        script: |
          flutter build ios --release --no-codesign
    artifacts:
      - build/ios/iphoneos/Runner.app
```

### 4. 配置自动签名（用于侧载）
Codemagic 支持使用自动证书：
1. 进入项目设置
2. 找到 "Code signing"
3. 选择 "Use automatic code signing"
4. 使用 Apple ID 配置（免费，用于侧载）

### 5. 开始构建
1. 推送代码到 GitHub
2. Codemagic 自动开始构建
3. 等待完成并下载 IPA

---

## 方案 D：借助朋友的 Mac（最简单）

如果您的朋友有 Mac：
1. 将项目代码传给他们（zip 或 GitHub）
2. 让他们执行以下步骤：
```bash
# 安装 Flutter
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install --cask flutter

# 克隆项目
git clone <你的GitHub仓库URL>
cd manga_player

# 编译
flutter build ios --release
```

3. 他们将 IPA 发给你

---

## 部署到 iPhone/iPad（免费侧载）

### 方法 1：使用 AltStore（推荐）

#### 在 iPhone/iPad 上安装 AltStore

**前置条件：**
- 需要一台 Windows/Mac 电脑（使用 AltServer）
- 或使用 iCloud 邮箱（需要 7 天刷新）

**步骤：**
1. 访问 https://altstore.io
2. 下载并安装 AltStore
3. 如果使用 AltServer：
   - 在电脑上运行 AltServer
   - 在 iOS 设置中信任开发者证书
   - 输入 AltServer 显示的 IP 地址

#### 侧载应用
1. 将 IPA 文件传到 iPhone/iPad（通过 AirDrop、邮件、云盘等）
2. 在 AltStore 中打开 IPA
3. AltStore 会自动安装应用
4. 首次启动时，在设置中信任开发者

**重要：**
- 每 7 天需要重新签名（AltStore 会提醒）
- 保持 AltServer 在同一网络

### 方法 2：使用 Sideloadly

1. 在 Windows/Mac 上安装 Sideloadly
2. 连接 iOS 设备（USB）
3. 将 IPA 拖入 Sideloadly
4. 输入 Apple ID 和密码
5. 点击开始侧载

**优势：**
- 不需要 AltServer 常驻运行
- 每 7 天一次重新签名

### 方法 3：使用 Cydia Impactor（已停用，不推荐）
- 不再维护，建议使用 AltStore

---

## 验证部署

### 1. 启动应用应用后，验证：
- ✓ 可以看到主界面
- ✓ 可以创建文件夹
- ✓ 可以导入图片
- ✓ 可以进入播放模式
- ✓ 手势控制正常工作
- ✓ 设置页面可以调整播放间隔
- ✓ Web 服务器可以启动

### 2. 测试 Web 上传功能
1. 在应用中启动 Web 服务器
2. 在同一网络的电脑浏览器中访问显示的 URL
3. 上传测试图片
4. 在应用中验证图片已导入

### 3. 测试播放功能
1. 创建测试文件夹，导入多张图片
2. 从第一张图片开始播放
3. 测试：
   - 自动播放
   - 左滑/右滑跳转
   - 上滑/下滑调整速度
   - 双击暂停/继续
   - 长按返回

---

## 常见问题

### Q1: 编译失败提示 "code signing error"
**A:** 使用 `--no-codesign` 标志或配置自动签名

### Q2: IPA 安装后立即闪退
**A:** 在设置 > 通用 > VPN与设备管理中信任开发者

### Q3: AltStore 提示证书已过期
**A:** 使用 AltServer 重新签名，或等待 7 天后更新

### Q4: Web 服务器无法访问
**A:** 确保设备和电脑在同一网络，关闭防火墙

### Q5: 图片无法加载
**A:** 检查文件权限，确保图片格式受支持

### Q6: 应用提示需要网络权限
**A:** 在 iOS 设置中允许应用访问本地网络（用于 Web 服务器）

---

## 维护和更新

### 更新应用
1. 修改代码
2. 推送到 GitHub
3. 重新构建 IPA
4. 通过 AltStore 侧载新版

### 数据备份
应用数据存储在 iOS 设备上，建议：
- 定期通过 iTunes/Finder 备份设备
- 或导出重要图片

---

## 推荐流程总结

**最快路径（约 2-3 小时）：**
1. ✅ 代码已完成（您已拥有）
2. ⏭ 使用 MacInCloud（1-2 小时，$1-2）
3. ⏭ 下载 IPA
4. ⏭ 通过 AltStore 侧载到设备
5. ✅ 测试使用

**免费路径（约 4-6 小时）：**
1. ✅ 代码已完成
2. ⏭ 配置 GitHub Actions 或 Codemagic
3. ⏭ 等待 CI/CD 构建（免费）
4. ⏭ 下载产物
5. ⏭ 使用 AltStore 侧载
6. ✅ 测试使用

---

## 联系支持

如果遇到问题：
- Flutter 文档：https://docs.flutter.dev
- AltStore 文档：https://altstore.io/faq
- GitHub Issues：在项目仓库创建 issue

---

**祝您使用愉快！**
