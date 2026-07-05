# 学宝

学宝是一个本机优先的小学生练习应用，使用 Flutter 和 Material Design 3 构建。当前版本包含数学和英文练习、语文和英文听写、背单词、学习游戏，以及使用 OpenAI 格式 TTS API 的朗读。

## 功能范围

- 不需要账号，练习记录保存在本机
- 首页可视化学习面板
- 内置数学和英文题目
- 内置语文词语和英文单词听写
- 使用 OpenAI 格式 TTS API 朗读
- 使用标准 JSON 导入数学题、英文题、英文单词、语文和英文听写词
- 可选配置 AI API 渠道，在练习中生成不透露答案的小提示
- AI 小提示每日次数可在设置中用管理密码调整
- 学习游戏包含倒计时、生命值、连击和得分
- 本机保存错题、错词和成绩记录
- 使用 Material Icons，不使用表情符号作为界面图标

## GitHub Actions 打包 APK

仓库已经配置 `.github/workflows/build-apk.yml`。

触发方式：

- 推送到 `main` 分支
- 在 GitHub Actions 页面手动点击 `Run workflow`

构建完成后，在 workflow run 的 Artifacts 中下载：

```text
xuebao-release-apk
```

其中包含：

```text
app-release.apk
```

## 本地开发

如果本机已经安装 Flutter，可以运行：

```bash
flutter create . --platforms=android --project-name xuebao --org com.fff122
flutter pub get
flutter run
```

本地打包：

```bash
flutter build apk --release
```

## 自定义导入格式

设置页支持标准 JSON 导入。数学计算题和英语练习题只需要写真实答案，应用会自动生成 3 个无关选项；数学应用题不生成选项，孩子直接输入答案。详细格式见 [JSON_IMPORT.md](JSON_IMPORT.md)。

## 项目结构

```text
lib/
  main.dart

.github/
  workflows/
    build-apk.yml
```

## 隐私说明

错题、听写记录和设置保存在当前手机本地。

TTS 朗读和 AI 小提示会调用你在本机配置的 API。题库和词库通过标准 JSON 导入，保存到当前手机本地。
