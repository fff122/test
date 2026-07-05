# JSON 导入格式

设置页使用统一 JSON 导入题库和词库。JSON 根节点必须是对象，支持 `questions`、`dictation`、`words` 三个数组。

## 总体结构

```json
{
  "version": 1,
  "questions": [],
  "dictation": [],
  "words": []
}
```

## 数学题

数学计算题只需要填真实答案，应用会自动生成 3 个无关选项。`type` 填 `calculation`。

```json
{
  "subject": "math",
  "grade": 1,
  "type": "calculation",
  "question": "8 + 7 = ?",
  "answer": "15",
  "explanation": "8 加 7 等于 15。"
}
```

数学应用题不要选项，孩子直接输入答案。`type` 填 `word_problem`。

```json
{
  "subject": "math",
  "grade": 1,
  "type": "word_problem",
  "question": "小明有 9 个苹果，送给同学 3 个，还剩几个？",
  "answer": "6",
  "explanation": "用 9 - 3 计算。"
}
```

## 英语练习题

英语练习题也只需要填真实答案。没有 `options` 时，应用会自动补齐 3 个干扰选项。

```json
{
  "subject": "english",
  "grade": 2,
  "question": "school 的中文意思是？",
  "answer": "学校",
  "explanation": "school 表示学校。"
}
```

## 英语单词

`words` 会同时进入背单词、英文听写和英文练习题。必须有 `word` 和 `meaning`。

```json
{
  "grade": 1,
  "word": "apple",
  "meaning": "苹果",
  "partOfSpeech": "n."
}
```

## 听写词库

语文只用于听写训练，不进入科目练习。

```json
{
  "subject": "chinese",
  "grade": 1,
  "text": "春天"
}
```

英语听写需要带中文提示，`hint` 或 `meaning` 都可以。

```json
{
  "subject": "english",
  "grade": 2,
  "text": "school",
  "hint": "学校"
}
```

## 字段说明

- `subject`: 支持 `math`、`english`、`chinese`，也支持 `数学`、`英语`、`语文`。
- `grade`: 1 到 6。
- `answer`: 真实答案。选择题可以只填真实答案，应用自动生成其他选项。
- `options`: 可选。如果你手动提供选项，应用会使用你提供的选项。
- `type`: 数学计算题用 `calculation`，数学应用题用 `word_problem`。
- `explanation`: 答题结束后显示的解析。AI 小提示不会直接告诉答案。

## 完整示例

```json
{
  "version": 1,
  "questions": [
    {
      "subject": "math",
      "grade": 1,
      "type": "calculation",
      "question": "8 + 7 = ?",
      "answer": "15",
      "explanation": "8 加 7 等于 15。"
    },
    {
      "subject": "math",
      "grade": 1,
      "type": "word_problem",
      "question": "小明有 9 个苹果，送给同学 3 个，还剩几个？",
      "answer": "6",
      "explanation": "用 9 - 3 计算。"
    }
  ],
  "dictation": [
    {"subject": "chinese", "grade": 1, "text": "春天"},
    {"subject": "english", "grade": 2, "text": "school", "hint": "学校"}
  ],
  "words": [
    {"grade": 1, "word": "apple", "meaning": "苹果", "partOfSpeech": "n."}
  ]
}
```
