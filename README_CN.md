<div align="center">
  <img src="assets/logo.png" alt="Loftify logo" width="96" />
  <h1>Loftify</h1>
  <p>基于 Flutter 的 Material 3 LOFTER 第三方客户端，支持 Android 与 Windows</p>
  <p>
    <img alt="版本 2.6.1" src="https://img.shields.io/badge/version-2.6.1-14C2BB?style=flat-square" />
    <img alt="Flutter 3.x" src="https://img.shields.io/badge/Flutter-3.x-027DFD?style=flat-square" />
    <img alt="Android" src="https://img.shields.io/badge/platform-Android-3DDC84?style=flat-square" />
    <img alt="Windows" src="https://img.shields.io/badge/platform-Windows-0078D6?style=flat-square" />
    <img alt="MIT 协议" src="https://img.shields.io/badge/license-MIT-9E9E9E?style=flat-square" />
  </p>
  <p><a href="README.md">English</a></p>
</div>

---

## 简介

Loftify 是一款基于 Flutter 的非官方 LOFTER 第三方客户端。本仓库是
[Robert-Stackflow/Loftify](https://github.com/Robert-Stackflow/Loftify)
的个人改版：在上游基础上叠加 Material 3 Expressive 界面重构、平板布局、
性能优化与问题修复，仅自用维护，不计划回传上游。

本改版的应用包名为 `com.loftify.yatmt`，可与其他构建共存安装。

## 主要特性

### Material 3 设计

- 全面的 Material 3 视觉语言：种子色调配色、语义化的颜色/动效/排印令牌，
  全应用采用 Material 3 组件
- 底部悬浮导航栏支持三种位置切换：居中浮动、右下停靠、底部全宽
- 悬浮栏的收起与展开由单一时钟驱动，采用 Material emphasized 缓动并带滚动
  迟滞阈值，动画顺滑且不抖动
- 所有动效均提供减弱动效、高对比度、降低透明度的无障碍回退

### 为平板而设计

- 平板竖屏使用与手机一致的外壳和底部悬浮栏；平板横屏使用 Material 3
  NavigationRail 侧边导航栏
- 内容排版按宽度自适应：信息流多列、个人页两栏
- 阅读页在平板上正文优先：正文占满整栏，相关推荐在下（可拖拽双栏仅保留给
  桌面窗口）

### 阅读与标签工具

- 标签长按（或右键）即可屏蔽；标签屏蔽页支持乙女向内容一键过滤
- 标签 LLM 智能分类，支持按分类持久过滤，新帖自动分类
- 标签分页按服务端返回的偏移量串联加载，并带逐页自动重试，长标签不再
  静默中断
- 搜索框采用 Material 3 SearchBar，输入联想不再逐键重建整页

### 性能

- 帖子滑动切换不再对整页做透明度合成（saveLayer）；对话框与底部面板去除
  全屏背景模糊，改用 Material 遮罩
- 手写按钮/提示框/涟漪动画栈整体替换为 Material 3 的 `IconButton`、
  `FilledButton`、`AlertDialog`、`ModalBottomSheet` 与 `SnackBar`
- Lottie 动画按资源共享、在后台 isolate 解析，点赞/庆祝等重型动画启动时预热
- 信息流图片按布局尺寸经有界解码管线加载；主题构建按主题实例缓存

### 更新检查

- 启动时默认检查本仓库的 GitHub Releases，发现新版本弹出更新对话框（含更新
  日志），可在通用设置中关闭
- 关于页提供「检查更新」手动入口

## 下载

前往 [Releases](https://github.com/Yar1991-Translation/Loftify/releases)
页面获取最新构建：

| 平台 | 产物 | 直链 |
| --- | --- | --- |
| Android | arm64-v8a APK | [Loftify-2.6.1-android-arm64.apk](https://github.com/Yar1991-Translation/Loftify/releases/download/v2.6.1/Loftify-2.6.1-android-arm64.apk) |
| Windows | x64 压缩包 | [Loftify-2.6.1-windows-x64.zip](https://github.com/Yar1991-Translation/Loftify/releases/download/v2.6.1/Loftify-2.6.1-windows-x64.zip) |

## 功能一览

| 能力 | 状态 |
| --- | --- |
| 首页推荐流 | 已支持 |
| 标签内推荐 | 已支持 |
| 屏蔽文章/视频 | 已支持 |
| 订阅（标签、合集、粮单） | 已支持 |
| 搜索 | 已支持 |
| 保存原图 | 已支持 |
| 合集与粮单 | 已支持 |
| 我的喜欢/推荐/收藏/足迹 | 已支持 |
| 我的作品/我的粮单 | 已支持 |
| 个人主页 | 已支持 |
| 检查更新 | 已支持 |
| 手势/密码锁 | 已支持 |
| 创作与发布 | 计划中 |
| 管理收藏/合集 | 计划中 |

## 从源码构建

前置条件：Flutter 稳定版（Dart 3.6+），已配置 Windows 桌面与 Android 工具链。

```bash
flutter pub get

# Android（单 ABI release APK）
flutter build apk --release --target-platform android-arm64

# Windows
flutter build windows --release
```

开发开关，通过 `--dart-define` 传入：

| 开关 | 作用 |
| --- | --- |
| `DEMO_MODE=true` | 全应用使用内置测试数据运行，无需账号与网络 |
| `FORCE_MOBILE_LAYOUT=true` | 桌面构建强制使用手机布局 |

```bash
flutter run --dart-define=DEMO_MODE=true
```

项目自带 730 个组件与单元测试，使用 `flutter test` 运行。

## 已知问题

- 2.4 版本后华为设备灰屏
- 标签页内容重复、九宫格布局选项待处理

## 更新日志

见应用内更新日志（关于页）或
[Releases](https://github.com/Yar1991-Translation/Loftify/releases) 页面。
更新日志自 2.6.0 起持续维护。

## 致谢

- 上游项目：[Robert-Stackflow/Loftify](https://github.com/Robert-Stackflow/Loftify)
- LOFTER 是网易旗下产品。本客户端为非官方第三方实现，与网易无关，亦未获得
  其认可。

## 协议

[MIT](LICENSE)，Copyright (c) 2022 Robert-Stackflow 及贡献者。
