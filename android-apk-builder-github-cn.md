# Android APK Builder Skill

`android-apk-builder` 是一个用于制作轻量安卓 APK 的 Codex skill。

它适合在没有完整 Android Studio / Gradle 环境时，帮助 Codex 从零创建一个简单安卓 App，并完成编译、打包、签名、验证，最终生成可以安装到安卓手机上的 `.apk` 文件。

## 功能介绍

这个 skill 可以帮助你完成：

- 从零创建简单安卓 App。
- 生成原生 Java `Activity` 项目。
- 创建 `AndroidManifest.xml`、资源文件、主题、应用名。
- 配置简易矢量启动图标。
- 在没有 Gradle 的情况下手工打包 APK。
- 使用 Android 命令行工具完成构建：
  - `aapt`
  - `javac`
  - `d8`
  - `zipalign`
  - `apksigner`
- 自动生成调试签名 keystore。
- 验证 APK 是否真的可安装。
- 在有 `adb` 的情况下安装到安卓设备。

## 适合做什么

适合制作这些小型安卓工具：

- 计算器
- 日常收支记录
- 备忘录
- 打卡工具
- 简单库存记录
- 小型表单记录工具
- 本地离线小工具
- 简单原型 App

不适合直接用于复杂商业级 Android 项目，比如多模块工程、Jetpack Compose、大量第三方依赖、复杂权限、应用商店发布签名等。

## 可用 Skill

### `$android-apk-builder`

用途：创建、打包、签名、验证轻量安卓 APK。

你可以这样调用：

```text
用 $android-apk-builder 做一个安卓计算器 APK
```

```text
用 $android-apk-builder 做一个日常收支记录 App，生成安卓安装包
```

```text
用 $android-apk-builder 把这个简单安卓项目打包成可安装 APK，并验证签名
```

也可以不用 `$`，直接说：

```text
用 android-apk-builder 做一个安卓记账软件
```

## Skill 目录结构

```text
android-apk-builder/
  SKILL.md
  agents/
    openai.yaml
  scripts/
    manual_apk_build.ps1
```

## 内置脚本

这个 skill 自带一个手工打包脚本：

```text
scripts/manual_apk_build.ps1
```

它适合这种简单 Android 项目结构：

```text
project/
  AndroidManifest.xml
  res/
  src/
    com/example/app/MainActivity.java
  build-apk.ps1
```

默认使用的 Android SDK 目录：

```text
workspace/
  android-sdk/
    platforms/android-28/android.jar
    build-tools/28.0.3/
```

如果 SDK 在别的位置，可以通过 `-SdkRoot` 指定。

## 构建流程

skill 会指导 Codex 按这个流程生成 APK：

1. 检查当前目录是否已有 Android/Gradle 项目。
2. 如果有 Gradle 项目，优先使用项目原有构建方式。
3. 如果没有项目，则创建最小 Android 项目。
4. 检查 Java、Android SDK、build-tools、adb 等工具。
5. 缺少 SDK 时，先查找本地路径，再请求允许下载官方 Android SDK 包。
6. 使用 `aapt` 编译资源。
7. 使用 `javac` 编译 Java 源码。
8. 使用 `d8` 生成 `classes.dex`。
9. 使用 `zipalign` 对齐 APK。
10. 使用 `apksigner` 签名 APK。
11. 验证 APK 内容、签名、包名、应用名和启动 Activity。

## 验证内容

最终交付 APK 前会检查：

- APK 中有 `classes.dex`。
- APK 中有 `AndroidManifest.xml`。
- APK 中有 `resources.arsc`。
- `zipalign` 验证通过。
- `apksigner verify` 验证通过。
- `aapt dump badging` 能识别：
  - 包名
  - 应用名
  - minSdk
  - targetSdk
  - 启动 Activity

## 安装方法

把 skill 文件夹复制到 Codex skills 目录：

```powershell
Copy-Item -Recurse .\android-apk-builder "$env:USERPROFILE\.codex\skills\android-apk-builder"
```

之后重新打开 Codex 会话，或在支持的环境中重新加载 skills。

## 示例任务

```text
用 $android-apk-builder 做一个安卓计算器
```

可能输出：

```text
APK 已生成：
D:\111\android-calculator\build\calculator.apk

验证已通过：
- classes.dex 存在
- zipalign 通过
- apksigner v1/v2 签名通过
- aapt 能识别应用名和启动 Activity
```

## 注意事项

- 这个 skill 更适合轻量、小型、离线、本地安装的 Android App。
- 如果项目已经是完整 Gradle 项目，它会优先使用项目自己的 Gradle 构建。
- 如果构建工具缺失，它会先查找本机已有 SDK，不会直接乱下载。
- 需要下载 Android SDK 时，应先请求用户允许。
- 如果没有生成 `classes.dex`，不能交付 APK。
