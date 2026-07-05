# 学宝

学宝是一个本机优先的小学生练习应用，使用 Flutter 和 Material Design 3 构建。当前版本包含数学、语文、英文练习，以及使用 OpenAI 格式 TTS API 的语文和英文听写。

## 功能范围

- 不需要账号，练习记录保存在本机
- 内置数学、语文、英文题目
- 内置语文词语和英文单词听写
- 使用 OpenAI 格式 TTS API 朗读
- 支持手动导入题库和听写词
- 可选配置 AI API 渠道，用 AI 识别图片并整理为本机题库
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

题库导入支持两种格式，AI 整理后可以先手动编辑再保存：

```text
选择题：题目|选项1|选项2|选项3|选项4|答案|解析
填空题：题目=答案
```

听写导入支持每行一个词语或单词，也可以用顿号、逗号、分号分隔。

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

TTS 朗读会调用你在本机配置的 OpenAI 格式 TTS API。AI 图片导入默认关闭，开启后所选图片会发送到你配置的 AI API 渠道；整理结果保存到本机题库。
