import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const XueBaoApp());
}

class XueBaoApp extends StatelessWidget {
  const XueBaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学宝',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFD),
      ),
      home: const XueBaoShell(),
    );
  }
}

enum Subject { math, chinese, english }

extension SubjectInfo on Subject {
  String get label {
    switch (this) {
      case Subject.math:
        return '数学';
      case Subject.chinese:
        return '语文';
      case Subject.english:
        return '英文';
    }
  }

  IconData get icon {
    switch (this) {
      case Subject.math:
        return Icons.calculate_outlined;
      case Subject.chinese:
        return Icons.menu_book_outlined;
      case Subject.english:
        return Icons.translate_outlined;
    }
  }

  Color get color {
    switch (this) {
      case Subject.math:
        return const Color(0xFF1A73E8);
      case Subject.chinese:
        return const Color(0xFFEA4335);
      case Subject.english:
        return const Color(0xFF188038);
    }
  }

  String get key => name;

  String get ttsLanguage {
    switch (this) {
      case Subject.math:
      case Subject.chinese:
        return 'zh-CN';
      case Subject.english:
        return 'en-US';
    }
  }
}

Subject subjectFromKey(String value) {
  return Subject.values.firstWhere(
    (subject) => subject.key == value,
    orElse: () => Subject.math,
  );
}

class PracticeQuestion {
  const PracticeQuestion({
    required this.id,
    required this.subject,
    required this.grade,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  final String id;
  final Subject subject;
  final int grade;
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'subject': subject.key,
      'grade': grade,
      'question': question,
      'options': options,
      'answer': answer,
      'explanation': explanation,
    };
  }

  factory PracticeQuestion.fromJson(Map<String, Object?> json) {
    return PracticeQuestion(
      id: json['id'] as String,
      subject: subjectFromKey(json['subject'] as String),
      grade: json['grade'] as int,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
      answer: json['answer'] as String,
      explanation: json['explanation'] as String,
    );
  }
}

class DictationItem {
  const DictationItem({
    required this.id,
    required this.subject,
    required this.grade,
    required this.text,
    required this.hint,
    required this.sentence,
  });

  final String id;
  final Subject subject;
  final int grade;
  final String text;
  final String hint;
  final String sentence;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'subject': subject.key,
      'grade': grade,
      'text': text,
      'hint': hint,
      'sentence': sentence,
    };
  }

  factory DictationItem.fromJson(Map<String, Object?> json) {
    return DictationItem(
      id: json['id'] as String,
      subject: subjectFromKey(json['subject'] as String),
      grade: json['grade'] as int,
      text: json['text'] as String,
      hint: json['hint'] as String,
      sentence: json['sentence'] as String,
    );
  }
}

class MistakeEntry {
  const MistakeEntry({
    required this.id,
    required this.sourceId,
    required this.subject,
    required this.grade,
    required this.mode,
    required this.question,
    required this.correctAnswer,
    required this.userAnswer,
    required this.wrongCount,
    required this.updatedAt,
  });

  final String id;
  final String sourceId;
  final Subject subject;
  final int grade;
  final String mode;
  final String question;
  final String correctAnswer;
  final String userAnswer;
  final int wrongCount;
  final DateTime updatedAt;

  MistakeEntry copyWith({
    String? userAnswer,
    int? wrongCount,
    DateTime? updatedAt,
  }) {
    return MistakeEntry(
      id: id,
      sourceId: sourceId,
      subject: subject,
      grade: grade,
      mode: mode,
      question: question,
      correctAnswer: correctAnswer,
      userAnswer: userAnswer ?? this.userAnswer,
      wrongCount: wrongCount ?? this.wrongCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'subject': subject.key,
      'grade': grade,
      'mode': mode,
      'question': question,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
      'wrongCount': wrongCount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MistakeEntry.fromJson(Map<String, Object?> json) {
    return MistakeEntry(
      id: json['id'] as String,
      sourceId: json['sourceId'] as String,
      subject: subjectFromKey(json['subject'] as String),
      grade: json['grade'] as int,
      mode: json['mode'] as String,
      question: json['question'] as String,
      correctAnswer: json['correctAnswer'] as String,
      userAnswer: json['userAnswer'] as String,
      wrongCount: json['wrongCount'] as int,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class PracticeRecord {
  const PracticeRecord({
    required this.id,
    required this.mode,
    required this.subject,
    required this.grade,
    required this.score,
    required this.total,
    required this.correct,
    required this.durationSeconds,
    required this.createdAt,
  });

  final String id;
  final String mode;
  final Subject subject;
  final int grade;
  final int score;
  final int total;
  final int correct;
  final int durationSeconds;
  final DateTime createdAt;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'mode': mode,
      'subject': subject.key,
      'grade': grade,
      'score': score,
      'total': total,
      'correct': correct,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PracticeRecord.fromJson(Map<String, Object?> json) {
    return PracticeRecord(
      id: json['id'] as String,
      mode: json['mode'] as String,
      subject: subjectFromKey(json['subject'] as String),
      grade: json['grade'] as int,
      score: json['score'] as int,
      total: json['total'] as int,
      correct: json['correct'] as int,
      durationSeconds: json['durationSeconds'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ResultItem {
  const ResultItem({
    required this.sourceId,
    required this.subject,
    required this.grade,
    required this.mode,
    required this.question,
    required this.correctAnswer,
    required this.userAnswer,
    required this.explanation,
    required this.isCorrect,
  });

  final String sourceId;
  final Subject subject;
  final int grade;
  final String mode;
  final String question;
  final String correctAnswer;
  final String userAnswer;
  final String explanation;
  final bool isCorrect;
}

class LocalStore {
  static const _mistakesKey = 'xuebao_mistakes';
  static const _recordsKey = 'xuebao_records';
  static const _customQuestionsKey = 'xuebao_custom_questions';
  static const _customDictationKey = 'xuebao_custom_dictation';

  static Future<List<MistakeEntry>> loadMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mistakesKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final values = jsonDecode(raw) as List<dynamic>;
    return values
        .map((item) => MistakeEntry.fromJson(Map<String, Object?>.from(item as Map)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<void> addMistakes(List<MistakeEntry> entries) async {
    if (entries.isEmpty) {
      return;
    }
    final current = await loadMistakes();
    final bySource = {for (final item in current) item.sourceId: item};
    for (final entry in entries) {
      final existing = bySource[entry.sourceId];
      if (existing == null) {
        bySource[entry.sourceId] = entry;
      } else {
        bySource[entry.sourceId] = existing.copyWith(
          userAnswer: entry.userAnswer,
          wrongCount: existing.wrongCount + 1,
          updatedAt: DateTime.now(),
        );
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _mistakesKey,
      jsonEncode(bySource.values.map((item) => item.toJson()).toList()),
    );
  }

  static Future<void> clearMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mistakesKey);
  }

  static Future<List<PracticeQuestion>> loadCustomQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customQuestionsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final values = jsonDecode(raw) as List<dynamic>;
    return values
        .map((item) => PracticeQuestion.fromJson(Map<String, Object?>.from(item as Map)))
        .toList();
  }

  static Future<void> addCustomQuestions(List<PracticeQuestion> questions) async {
    if (questions.isEmpty) {
      return;
    }
    final current = await loadCustomQuestions();
    final next = [...questions, ...current].take(500).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customQuestionsKey,
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }

  static Future<void> clearCustomQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customQuestionsKey);
  }

  static Future<List<DictationItem>> loadCustomDictation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customDictationKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final values = jsonDecode(raw) as List<dynamic>;
    return values
        .map((item) => DictationItem.fromJson(Map<String, Object?>.from(item as Map)))
        .toList();
  }

  static Future<void> addCustomDictation(List<DictationItem> items) async {
    if (items.isEmpty) {
      return;
    }
    final current = await loadCustomDictation();
    final next = [...items, ...current].take(300).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customDictationKey,
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }

  static Future<void> clearCustomDictation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customDictationKey);
  }

  static Future<List<PracticeRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recordsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final values = jsonDecode(raw) as List<dynamic>;
    return values
        .map((item) => PracticeRecord.fromJson(Map<String, Object?>.from(item as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> addRecord(PracticeRecord record) async {
    final records = await loadRecords();
    final next = [record, ...records].take(50).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _recordsKey,
      jsonEncode(next.map((item) => item.toJson()).toList()),
    );
  }
}

String normalizeAnswer(String value, Subject subject) {
  var normalized = value.trim().replaceAll(RegExp(r'\s+'), '');
  normalized = normalized.replaceAll(RegExp(r'[，。！？,.!?]'), '');
  if (subject == Subject.english) {
    normalized = normalized.toLowerCase();
  }
  return normalized;
}

String formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remain = seconds % 60;
  if (minutes == 0) {
    return '$remain 秒';
  }
  return '$minutes 分 $remain 秒';
}

const questionBank = <PracticeQuestion>[
  PracticeQuestion(
    id: 'math_1_001',
    subject: Subject.math,
    grade: 1,
    question: '3 + 5 = ?',
    options: ['6', '7', '8', '9'],
    answer: '8',
    explanation: '3 加 5 等于 8。',
  ),
  PracticeQuestion(
    id: 'math_1_002',
    subject: Subject.math,
    grade: 1,
    question: '10 - 4 = ?',
    options: ['5', '6', '7', '8'],
    answer: '6',
    explanation: '10 减 4 等于 6。',
  ),
  PracticeQuestion(
    id: 'math_2_001',
    subject: Subject.math,
    grade: 2,
    question: '4 × 3 = ?',
    options: ['7', '10', '12', '14'],
    answer: '12',
    explanation: '4 个 3 相加是 12。',
  ),
  PracticeQuestion(
    id: 'math_3_001',
    subject: Subject.math,
    grade: 3,
    question: '36 ÷ 6 = ?',
    options: ['4', '5', '6', '7'],
    answer: '6',
    explanation: '6 乘 6 等于 36，所以 36 除以 6 等于 6。',
  ),
  PracticeQuestion(
    id: 'chinese_1_001',
    subject: Subject.chinese,
    grade: 1,
    question: '“日”字共有几画？',
    options: ['3 画', '4 画', '5 画', '6 画'],
    answer: '4 画',
    explanation: '“日”字共有 4 画。',
  ),
  PracticeQuestion(
    id: 'chinese_2_001',
    subject: Subject.chinese,
    grade: 2,
    question: '下面哪个词语表示颜色？',
    options: ['明亮', '红色', '认真', '跑步'],
    answer: '红色',
    explanation: '“红色”表示颜色。',
  ),
  PracticeQuestion(
    id: 'chinese_3_001',
    subject: Subject.chinese,
    grade: 3,
    question: '“专心致志”的意思更接近哪一项？',
    options: ['非常认真', '跑得很快', '声音很大', '天气很好'],
    answer: '非常认真',
    explanation: '“专心致志”表示一心一意，注意力很集中。',
  ),
  PracticeQuestion(
    id: 'english_1_001',
    subject: Subject.english,
    grade: 1,
    question: 'apple 的中文意思是？',
    options: ['苹果', '书包', '小猫', '铅笔'],
    answer: '苹果',
    explanation: 'apple 表示苹果。',
  ),
  PracticeQuestion(
    id: 'english_2_001',
    subject: Subject.english,
    grade: 2,
    question: '选择 “狗” 的英文。',
    options: ['cat', 'dog', 'book', 'desk'],
    answer: 'dog',
    explanation: 'dog 表示狗。',
  ),
  PracticeQuestion(
    id: 'english_3_001',
    subject: Subject.english,
    grade: 3,
    question: 'I like milk. 这句话的意思是？',
    options: ['我喜欢牛奶。', '我有一本书。', '他喜欢苹果。', '这是我的尺子。'],
    answer: '我喜欢牛奶。',
    explanation: 'like 表示喜欢，milk 表示牛奶。',
  ),
];

const dictationBank = <DictationItem>[
  DictationItem(
    id: 'dict_cn_1_001',
    subject: Subject.chinese,
    grade: 1,
    text: '春天',
    hint: '季节',
    sentence: '春天来了，花儿开了。',
  ),
  DictationItem(
    id: 'dict_cn_1_002',
    subject: Subject.chinese,
    grade: 1,
    text: '朋友',
    hint: '一起学习和玩耍的人',
    sentence: '我和朋友一起读书。',
  ),
  DictationItem(
    id: 'dict_cn_2_001',
    subject: Subject.chinese,
    grade: 2,
    text: '明亮',
    hint: '光线充足',
    sentence: '教室里的灯很明亮。',
  ),
  DictationItem(
    id: 'dict_cn_3_001',
    subject: Subject.chinese,
    grade: 3,
    text: '认真',
    hint: '学习态度',
    sentence: '她认真地完成作业。',
  ),
  DictationItem(
    id: 'dict_en_1_001',
    subject: Subject.english,
    grade: 1,
    text: 'apple',
    hint: '苹果',
    sentence: 'I have an apple.',
  ),
  DictationItem(
    id: 'dict_en_1_002',
    subject: Subject.english,
    grade: 1,
    text: 'book',
    hint: '书',
    sentence: 'This is my book.',
  ),
  DictationItem(
    id: 'dict_en_2_001',
    subject: Subject.english,
    grade: 2,
    text: 'school',
    hint: '学校',
    sentence: 'I go to school.',
  ),
  DictationItem(
    id: 'dict_en_3_001',
    subject: Subject.english,
    grade: 3,
    text: 'family',
    hint: '家庭',
    sentence: 'I love my family.',
  ),
];

class XueBaoShell extends StatefulWidget {
  const XueBaoShell({super.key});

  @override
  State<XueBaoShell> createState() => _XueBaoShellState();
}

class _XueBaoShellState extends State<XueBaoShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const PracticeEntryPage(),
      const DictationEntryPage(),
      const MistakesPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: '练习',
          ),
          NavigationDestination(
            icon: Icon(Icons.record_voice_over_outlined),
            selectedIcon: Icon(Icons.record_voice_over),
            label: '听写',
          ),
          NavigationDestination(
            icon: Icon(Icons.error_outline),
            selectedIcon: Icon(Icons.error),
            label: '错题',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        Text('学宝', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('本地练习、本地听写、本机保存', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.92,
          children: Subject.values.map((subject) => SubjectCard(subject: subject)).toList(),
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<PracticeRecord>>(
          future: LocalStore.loadRecords(),
          builder: (context, snapshot) {
            final records = snapshot.data ?? [];
            final latest = records.isEmpty ? null : records.first;
            return AppPanel(
              icon: Icons.insights_outlined,
              title: '最近学习',
              child: latest == null
                  ? const Text('还没有学习记录，先完成一次练习或听写。')
                  : Text(
                      '${latest.subject.label} ${latest.mode}：${latest.score} 分，'
                      '${latest.correct}/${latest.total} 正确，用时 ${formatDuration(latest.durationSeconds)}',
                    ),
            );
          },
        ),
        const SizedBox(height: 12),
        const AppPanel(
          icon: Icons.security_outlined,
          title: '本地隐私',
          child: Text('学习数据只保存在当前手机，不上传服务器。'),
        ),
      ],
    );
  }
}

class SubjectCard extends StatelessWidget {
  const SubjectCard({required this.subject, super.key});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: subject.color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(subject.icon, color: subject.color, size: 34),
            const SizedBox(height: 12),
            Text(subject.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class PracticeEntryPage extends StatefulWidget {
  const PracticeEntryPage({super.key});

  @override
  State<PracticeEntryPage> createState() => _PracticeEntryPageState();
}

class _PracticeEntryPageState extends State<PracticeEntryPage> {
  Subject _subject = Subject.math;
  int _grade = 1;
  late Future<List<PracticeQuestion>> _customFuture = LocalStore.loadCustomQuestions();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle(icon: Icons.assignment_outlined, title: '科目练习', subtitle: '选择科目和年级后开始做题'),
        const SizedBox(height: 20),
        SubjectSelector(value: _subject, onChanged: (value) => setState(() => _subject = value)),
        const SizedBox(height: 18),
        GradeSelector(value: _grade, onChanged: (value) => setState(() => _grade = value)),
        const SizedBox(height: 18),
        FutureBuilder<List<PracticeQuestion>>(
          future: _customFuture,
          builder: (context, snapshot) {
            final custom = snapshot.data ?? [];
            final questions = _questionsForCurrentSelection(custom);
            final customCount = questions.where((item) => item.id.startsWith('custom_question_')).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPanel(
                  icon: Icons.fact_check_outlined,
                  title: '当前题目',
                  child: Text('已匹配 ${questions.length} 道题，其中自定义 $customCount 道。'),
                ),
                const SizedBox(height: 18),
                AppPanel(
                  icon: Icons.document_scanner_outlined,
                  title: '导入题库',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('可以拍照或从相册选择题目，OCR 后编辑确认，再保存到本机题库。'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _openQuestionImport(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('拍照识别'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _openQuestionImport(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('相册识别'),
                          ),
                          OutlinedButton.icon(
                            onPressed: custom.isEmpty
                                ? null
                                : () async {
                                    await LocalStore.clearCustomQuestions();
                                    if (mounted) {
                                      setState(() => _customFuture = LocalStore.loadCustomQuestions());
                                    }
                                  },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('清空自定义'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: questions.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuizPage(subject: _subject, grade: _grade, questions: questions),
                            ),
                          );
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始练习'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<PracticeQuestion> _questionsForCurrentSelection(List<PracticeQuestion> custom) {
    return [
      ...custom,
      ...questionBank,
    ].where((item) => item.subject == _subject && item.grade == _grade).toList();
  }

  Future<void> _openQuestionImport(ImageSource source) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OcrQuestionImportPage(
          initialSubject: _subject,
          initialGrade: _grade,
          source: source,
        ),
      ),
    );
    if (mounted) {
      setState(() => _customFuture = LocalStore.loadCustomQuestions());
    }
  }
}

class DictationEntryPage extends StatefulWidget {
  const DictationEntryPage({super.key});

  @override
  State<DictationEntryPage> createState() => _DictationEntryPageState();
}

class _DictationEntryPageState extends State<DictationEntryPage> {
  Subject _subject = Subject.chinese;
  int _grade = 1;
  late Future<List<DictationItem>> _customFuture = LocalStore.loadCustomDictation();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle(icon: Icons.record_voice_over_outlined, title: '听写训练', subtitle: '使用手机系统 TTS 朗读'),
        const SizedBox(height: 20),
        SubjectSelector(
          value: _subject,
          subjects: const [Subject.chinese, Subject.english],
          onChanged: (value) => setState(() => _subject = value),
        ),
        const SizedBox(height: 18),
        GradeSelector(value: _grade, onChanged: (value) => setState(() => _grade = value)),
        const SizedBox(height: 18),
        FutureBuilder<List<DictationItem>>(
          future: _customFuture,
          builder: (context, snapshot) {
            final custom = snapshot.data ?? [];
            final items = _itemsForCurrentSelection(custom);
            final customCount = items.where((item) => item.id.startsWith('custom_')).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPanel(
                  icon: Icons.hearing_outlined,
                  title: '听写说明',
                  child: Text(
                    '已匹配 ${items.length} 个听写内容，其中自定义 $customCount 个。'
                    '朗读质量取决于手机系统 TTS 引擎和离线语音包。',
                  ),
                ),
                const SizedBox(height: 18),
                AppPanel(
                  icon: Icons.document_scanner_outlined,
                  title: '导入听写本',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('可以拍照或从相册选择词语表，文字识别在手机本地完成，识别后可编辑再保存。'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _openOcrImport(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('拍照识别'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _openOcrImport(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('相册识别'),
                          ),
                          OutlinedButton.icon(
                            onPressed: custom.isEmpty
                                ? null
                                : () async {
                                    await LocalStore.clearCustomDictation();
                                    if (mounted) {
                                      setState(() => _customFuture = LocalStore.loadCustomDictation());
                                    }
                                  },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('清空自定义'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: items.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DictationSessionPage(subject: _subject, grade: _grade, items: items),
                            ),
                          );
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始听写'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  List<DictationItem> _itemsForCurrentSelection(List<DictationItem> custom) {
    return [
      ...custom,
      ...dictationBank,
    ].where((item) => item.subject == _subject && item.grade == _grade).toList();
  }

  Future<void> _openOcrImport(ImageSource source) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OcrImportPage(
          initialSubject: _subject,
          initialGrade: _grade,
          source: source,
        ),
      ),
    );
    if (mounted) {
      setState(() => _customFuture = LocalStore.loadCustomDictation());
    }
  }
}

class OcrQuestionImportPage extends StatefulWidget {
  const OcrQuestionImportPage({
    required this.initialSubject,
    required this.initialGrade,
    required this.source,
    super.key,
  });

  final Subject initialSubject;
  final int initialGrade;
  final ImageSource source;

  @override
  State<OcrQuestionImportPage> createState() => _OcrQuestionImportPageState();
}

class _OcrQuestionImportPageState extends State<OcrQuestionImportPage> {
  final _picker = ImagePicker();
  final _rawController = TextEditingController();
  late Subject _subject = widget.initialSubject;
  late int _grade = widget.initialGrade;
  bool _recognizing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickAndRecognize());
  }

  @override
  void dispose() {
    _rawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = parseQuestionText(_rawController.text, _subject, _grade);

    return Scaffold(
      appBar: AppBar(title: const Text('导入题库')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PageTitle(
            icon: widget.source == ImageSource.camera ? Icons.photo_camera_outlined : Icons.photo_library_outlined,
            title: widget.source == ImageSource.camera ? '拍照识别' : '相册识别',
            subtitle: '识别后可编辑，保存到本机题库',
          ),
          const SizedBox(height: 18),
          SubjectSelector(value: _subject, onChanged: (value) => setState(() => _subject = value)),
          const SizedBox(height: 16),
          GradeSelector(value: _grade, onChanged: (value) => setState(() => _grade = value)),
          const SizedBox(height: 16),
          const AppPanel(
            icon: Icons.rule_outlined,
            title: '支持格式',
            child: Text(
              '选择题：题目|选项1|选项2|选项3|选项4|答案|解析\n'
              '填空题：题目=答案\n'
              'OCR 后请先检查文字，再保存。',
            ),
          ),
          const SizedBox(height: 16),
          if (_recognizing)
            const AppPanel(
              icon: Icons.document_scanner_outlined,
              title: '正在识别',
              child: LinearProgressIndicator(),
            )
          else
            AppPanel(
              icon: Icons.edit_note_outlined,
              title: '识别文本',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _rawController,
                    minLines: 10,
                    maxLines: 16,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '例如：3 + 5 = ?|6|7|8|9|8|3 加 5 等于 8。',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Text('将保存 ${questions.length} 道题。'),
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          AppPanel(
            icon: Icons.list_alt_outlined,
            title: '保存预览',
            child: questions.isEmpty
                ? const Text('暂无可保存题目。')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: questions
                        .take(8)
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('${item.question}  答案：${item.answer}'),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _recognizing ? null : _pickAndRecognize,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新选择'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: questions.isEmpty || _recognizing ? null : () => _save(questions),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndRecognize() async {
    setState(() {
      _recognizing = true;
      _message = null;
    });

    try {
      final image = await _picker.pickImage(source: widget.source, imageQuality: 92);
      if (image == null) {
        if (mounted) {
          setState(() {
            _recognizing = false;
            _message = '没有选择图片。';
          });
        }
        return;
      }

      final recognizer = TextRecognizer(
        script: _subject == Subject.english ? TextRecognitionScript.latin : TextRecognitionScript.chinese,
      );
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText;
      try {
        recognizedText = await recognizer.processImage(inputImage);
      } finally {
        await recognizer.close();
      }

      final text = recognizedText.blocks
          .expand((block) => block.lines)
          .map((line) => line.text)
          .where((line) => line.trim().isNotEmpty)
          .join('\n');

      if (mounted) {
        setState(() {
          _rawController.text = text;
          _recognizing = false;
          _message = text.isEmpty ? '没有识别到文字，请换一张更清晰的图片。' : null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _recognizing = false;
          _message = '识别失败：$error';
        });
      }
    }
  }

  Future<void> _save(List<PracticeQuestion> questions) async {
    await LocalStore.addCustomQuestions(questions);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已保存 ${questions.length} 道题。')));
    Navigator.of(context).pop();
  }
}

List<PracticeQuestion> parseQuestionText(String text, Subject subject, int grade) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final questions = <PracticeQuestion>[];
  final lines = text
      .split(RegExp(r'[\n\r]+'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  for (final line in lines) {
    final parts = line.split('|').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    if (parts.length >= 6) {
      final options = parts.sublist(1, parts.length - 2);
      if (options.length >= 2) {
        final answer = resolveOptionAnswer(parts[parts.length - 2], options);
        questions.add(
          PracticeQuestion(
            id: 'custom_question_${now}_${questions.length}',
            subject: subject,
            grade: grade,
            question: parts.first,
            options: options,
            answer: answer,
            explanation: parts.last,
          ),
        );
      }
      continue;
    }

    final answerMatch = RegExp(r'^(.+?)\s*[=＝]\s*(.+)$').firstMatch(line);
    if (answerMatch != null) {
      final question = answerMatch.group(1)!.trim();
      final answer = answerMatch.group(2)!.trim();
      if (question.length >= 2 && answer.isNotEmpty) {
        questions.add(
          PracticeQuestion(
            id: 'custom_question_${now}_${questions.length}',
            subject: subject,
            grade: grade,
            question: '$question = ?',
            options: const [],
            answer: answer,
            explanation: '自定义题目。',
          ),
        );
      }
    }
  }

  return questions;
}

String resolveOptionAnswer(String rawAnswer, List<String> options) {
  final normalized = rawAnswer.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  const letterIndexes = {'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4, 'F': 5};
  final letterIndex = letterIndexes[normalized];
  if (letterIndex != null && letterIndex < options.length) {
    return options[letterIndex];
  }

  final numberIndex = int.tryParse(normalized);
  if (numberIndex != null && numberIndex >= 1 && numberIndex <= options.length) {
    return options[numberIndex - 1];
  }

  return rawAnswer.trim();
}

class OcrImportPage extends StatefulWidget {
  const OcrImportPage({
    required this.initialSubject,
    required this.initialGrade,
    required this.source,
    super.key,
  });

  final Subject initialSubject;
  final int initialGrade;
  final ImageSource source;

  @override
  State<OcrImportPage> createState() => _OcrImportPageState();
}

class _OcrImportPageState extends State<OcrImportPage> {
  final _picker = ImagePicker();
  final _rawController = TextEditingController();
  late Subject _subject = widget.initialSubject;
  late int _grade = widget.initialGrade;
  bool _recognizing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickAndRecognize());
  }

  @override
  void dispose() {
    _rawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final words = parseDictationText(_rawController.text);

    return Scaffold(
      appBar: AppBar(title: const Text('导入听写本')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PageTitle(
            icon: widget.source == ImageSource.camera ? Icons.photo_camera_outlined : Icons.photo_library_outlined,
            title: widget.source == ImageSource.camera ? '拍照识别' : '相册识别',
            subtitle: '识别后可编辑，保存到本机听写本',
          ),
          const SizedBox(height: 18),
          SubjectSelector(
            value: _subject,
            subjects: const [Subject.chinese, Subject.english],
            onChanged: (value) => setState(() => _subject = value),
          ),
          const SizedBox(height: 16),
          GradeSelector(value: _grade, onChanged: (value) => setState(() => _grade = value)),
          const SizedBox(height: 16),
          if (_recognizing)
            const AppPanel(
              icon: Icons.document_scanner_outlined,
              title: '正在识别',
              child: LinearProgressIndicator(),
            )
          else
            AppPanel(
              icon: Icons.edit_note_outlined,
              title: '识别文本',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _rawController,
                    minLines: 8,
                    maxLines: 14,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '每行一个词语或单词，也可以用顿号、逗号、分号分隔。',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Text('将保存 ${words.length} 个听写内容。'),
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    Text(_message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          AppPanel(
            icon: Icons.list_alt_outlined,
            title: '保存预览',
            child: words.isEmpty
                ? const Text('暂无可保存内容。')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: words.take(40).map((word) => Chip(label: Text(word))).toList(),
                  ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _recognizing ? null : _pickAndRecognize,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新选择'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: words.isEmpty || _recognizing ? null : () => _save(words),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndRecognize() async {
    setState(() {
      _recognizing = true;
      _message = null;
    });

    try {
      final image = await _picker.pickImage(source: widget.source, imageQuality: 92);
      if (image == null) {
        if (mounted) {
          setState(() {
            _recognizing = false;
            _message = '没有选择图片。';
          });
        }
        return;
      }

      final recognizer = TextRecognizer(
        script: _subject == Subject.chinese ? TextRecognitionScript.chinese : TextRecognitionScript.latin,
      );
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText;
      try {
        recognizedText = await recognizer.processImage(inputImage);
      } finally {
        await recognizer.close();
      }

      final text = recognizedText.blocks
          .expand((block) => block.lines)
          .map((line) => line.text)
          .where((line) => line.trim().isNotEmpty)
          .join('\n');

      if (mounted) {
        setState(() {
          _rawController.text = text;
          _recognizing = false;
          _message = text.isEmpty ? '没有识别到文字，请换一张更清晰的图片。' : null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _recognizing = false;
          _message = '识别失败：$error';
        });
      }
    }
  }

  Future<void> _save(List<String> words) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final items = words
        .asMap()
        .entries
        .map(
          (entry) => DictationItem(
            id: 'custom_${now}_${entry.key}',
            subject: _subject,
            grade: _grade,
            text: entry.value,
            hint: _subject == Subject.english ? '自定义英文听写' : '自定义语文听写',
            sentence: '来自拍照或相册文字识别。',
          ),
        )
        .toList();
    await LocalStore.addCustomDictation(items);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已保存 ${items.length} 个听写内容。')));
    Navigator.of(context).pop();
  }
}

List<String> parseDictationText(String text) {
  final values = text
      .split(RegExp(r'[\n\r,，;；、]+'))
      .map((item) => item.trim())
      .where((item) => item.length >= 2)
      .toSet()
      .toList();
  values.sort();
  return values;
}

class QuizPage extends StatefulWidget {
  const QuizPage({
    required this.subject,
    required this.grade,
    required this.questions,
    super.key,
  });

  final Subject subject;
  final int grade;
  final List<PracticeQuestion> questions;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final _answers = <String, String>{};
  final _fillController = TextEditingController();
  final _startAt = DateTime.now();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _syncFillController();
  }

  @override
  void dispose() {
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_index];
    final answered = _answers.values.where((value) => value.trim().isNotEmpty).length;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.subject.label}练习')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LinearProgressIndicator(value: (_index + 1) / widget.questions.length),
          const SizedBox(height: 16),
          Text('第 ${_index + 1} 题 / 共 ${widget.questions.length} 题', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 16),
          Text(question.question, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          if (question.options.isEmpty)
            TextField(
              controller: _fillController,
              decoration: const InputDecoration(
                labelText: '输入答案',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _answers[question.id] = value,
            )
          else
            ...question.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RadioListTile<String>(
                  value: option,
                  groupValue: _answers[question.id],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _answers[question.id] = value);
                    }
                  },
                  title: Text(option),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text('已完成 $answered / ${widget.questions.length}', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _index == 0 ? null : () => _moveTo(_index - 1),
                child: const Text('上一题'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _index == widget.questions.length - 1 ? _submit : () => _moveTo(_index + 1),
                child: Text(_index == widget.questions.length - 1 ? '交卷' : '下一题'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _moveTo(int index) {
    setState(() {
      _index = index;
      _syncFillController();
    });
  }

  void _syncFillController() {
    final question = widget.questions[_index];
    _fillController.text = question.options.isEmpty ? (_answers[question.id] ?? '') : '';
  }

  Future<void> _submit() async {
    final results = widget.questions.map((question) {
      final answer = _answers[question.id] ?? '';
      final correct = question.options.isEmpty
          ? normalizeAnswer(answer, question.subject) == normalizeAnswer(question.answer, question.subject)
          : answer == question.answer;
      return ResultItem(
        sourceId: question.id,
        subject: question.subject,
        grade: question.grade,
        mode: '练习',
        question: question.question,
        correctAnswer: question.answer,
        userAnswer: answer.isEmpty ? '未作答' : answer,
        explanation: question.explanation,
        isCorrect: correct,
      );
    }).toList();
    await saveResultAndOpenPage(context, results, _startAt);
  }
}

class DictationSessionPage extends StatefulWidget {
  const DictationSessionPage({
    required this.subject,
    required this.grade,
    required this.items,
    super.key,
  });

  final Subject subject;
  final int grade;
  final List<DictationItem> items;

  @override
  State<DictationSessionPage> createState() => _DictationSessionPageState();
}

class _DictationSessionPageState extends State<DictationSessionPage> {
  final _tts = FlutterTts();
  final _controller = TextEditingController();
  final _answers = <String, String>{};
  final _startAt = DateTime.now();
  int _index = 0;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
  }

  @override
  void dispose() {
    _tts.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];

    return Scaffold(
      appBar: AppBar(title: Text('${widget.subject.label}听写')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LinearProgressIndicator(value: (_index + 1) / widget.items.length),
          const SizedBox(height: 16),
          Text('第 ${_index + 1} 个 / 共 ${widget.items.length} 个', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 18),
          Center(
            child: FilledButton.tonalIcon(
              onPressed: _speakCurrent,
              icon: const Icon(Icons.volume_up),
              label: const Text('播放'),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _slow = !_slow);
                _speakCurrent();
              },
              icon: const Icon(Icons.slow_motion_video),
              label: Text(_slow ? '慢速播放中' : '慢速播放'),
            ),
          ),
          const SizedBox(height: 24),
          AppPanel(
            icon: Icons.lightbulb_outline,
            title: '提示',
            child: Text(item.hint),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: '输入听到的内容',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
            onChanged: (value) => _answers[item.id] = value,
          ),
          const SizedBox(height: 12),
          Text('例句会在结果页显示，听写时先专注输入。', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _index == 0 ? null : _previous,
                child: const Text('上一个'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _index == widget.items.length - 1 ? _submit : _next,
                child: Text(_index == widget.items.length - 1 ? '完成' : '下一个'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _speakCurrent() async {
    final item = widget.items[_index];
    await _tts.setLanguage(widget.subject.ttsLanguage);
    await _tts.setSpeechRate(_slow ? 0.35 : 0.48);
    await _tts.setPitch(1);
    await _tts.stop();
    await _tts.speak(item.text);
  }

  void _previous() {
    _answers[widget.items[_index].id] = _controller.text;
    setState(() {
      _index--;
      _controller.text = _answers[widget.items[_index].id] ?? '';
    });
    _speakCurrent();
  }

  void _next() {
    _answers[widget.items[_index].id] = _controller.text;
    setState(() {
      _index++;
      _controller.text = _answers[widget.items[_index].id] ?? '';
    });
    _speakCurrent();
  }

  Future<void> _submit() async {
    _answers[widget.items[_index].id] = _controller.text;
    final results = widget.items.map((item) {
      final userAnswer = _answers[item.id] ?? '';
      final correct = normalizeAnswer(userAnswer, item.subject) == normalizeAnswer(item.text, item.subject);
      return ResultItem(
        sourceId: item.id,
        subject: item.subject,
        grade: item.grade,
        mode: '听写',
        question: '听写：${item.hint}',
        correctAnswer: item.text,
        userAnswer: userAnswer.isEmpty ? '未作答' : userAnswer,
        explanation: item.sentence,
        isCorrect: correct,
      );
    }).toList();
    await _tts.stop();
    if (!mounted) {
      return;
    }
    await saveResultAndOpenPage(context, results, _startAt);
  }
}

Future<void> saveResultAndOpenPage(
  BuildContext context,
  List<ResultItem> results,
  DateTime startAt,
) async {
  final correct = results.where((item) => item.isCorrect).length;
  final score = (correct / results.length * 100).round();
  final duration = DateTime.now().difference(startAt).inSeconds;
  final wrongEntries = results
      .where((item) => !item.isCorrect)
      .map(
        (item) => MistakeEntry(
          id: '${item.sourceId}_${DateTime.now().millisecondsSinceEpoch}',
          sourceId: item.sourceId,
          subject: item.subject,
          grade: item.grade,
          mode: item.mode,
          question: item.question,
          correctAnswer: item.correctAnswer,
          userAnswer: item.userAnswer,
          wrongCount: 1,
          updatedAt: DateTime.now(),
        ),
      )
      .toList();

  await LocalStore.addMistakes(wrongEntries);
  await LocalStore.addRecord(
    PracticeRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mode: results.first.mode,
      subject: results.first.subject,
      grade: results.first.grade,
      score: score,
      total: results.length,
      correct: correct,
      durationSeconds: duration,
      createdAt: DateTime.now(),
    ),
  );

  if (!context.mounted) {
    return;
  }
  await Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => ResultPage(results: results, score: score, correct: correct, durationSeconds: duration),
    ),
  );
}

class ResultPage extends StatelessWidget {
  const ResultPage({
    required this.results,
    required this.score,
    required this.correct,
    required this.durationSeconds,
    super.key,
  });

  final List<ResultItem> results;
  final int score;
  final int correct;
  final int durationSeconds;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('结果')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$score 分', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('正确 $correct / ${results.length}，用时 ${formatDuration(durationSeconds)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...results.map(
            (item) => Card(
              elevation: 0,
              child: ListTile(
                leading: Icon(
                  item.isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: item.isCorrect ? const Color(0xFF188038) : const Color(0xFFEA4335),
                ),
                title: Text(item.question),
                subtitle: Text(
                  '你的答案：${item.userAnswer}\n正确答案：${item.correctAnswer}\n解析：${item.explanation}',
                ),
                isThreeLine: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MistakesPage extends StatefulWidget {
  const MistakesPage({super.key});

  @override
  State<MistakesPage> createState() => _MistakesPageState();
}

class _MistakesPageState extends State<MistakesPage> {
  late Future<List<MistakeEntry>> _future = LocalStore.loadMistakes();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle(icon: Icons.error_outline, title: '错题本', subtitle: '自动保存练习和听写错误'),
        const SizedBox(height: 16),
        FutureBuilder<List<MistakeEntry>>(
          future: _future,
          builder: (context, snapshot) {
            final mistakes = snapshot.data ?? [];
            if (mistakes.isEmpty) {
              return const AppPanel(
                icon: Icons.task_alt_outlined,
                title: '暂无错题',
                child: Text('完成练习或听写后，错误内容会保存在这里。'),
              );
            }
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      await LocalStore.clearMistakes();
                      if (mounted) {
                        setState(() => _future = LocalStore.loadMistakes());
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('清空'),
                  ),
                ),
                ...mistakes.map(
                  (item) => Card(
                    elevation: 0,
                    child: ListTile(
                      leading: Icon(item.subject.icon, color: item.subject.color),
                      title: Text(item.question),
                      subtitle: Text(
                        '${item.subject.label} ${item.grade} 年级 ${item.mode}\n'
                        '你的答案：${item.userAnswer}\n正确答案：${item.correctAnswer}\n错误次数：${item.wrongCount}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _tts = FlutterTts();

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle(icon: Icons.settings_outlined, title: '设置', subtitle: '本地设置和 TTS 测试'),
        const SizedBox(height: 16),
        AppPanel(
          icon: Icons.volume_up_outlined,
          title: '系统 TTS 测试',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('朗读效果由手机系统语音引擎决定。若无法朗读，请在系统设置中安装中文或英文语音包。'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _speak('zh-CN', '你好，欢迎使用学宝。'),
                    icon: const Icon(Icons.record_voice_over_outlined),
                    label: const Text('测试中文'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _speak('en-US', 'Hello, welcome to Xuebao.'),
                    icon: const Icon(Icons.record_voice_over_outlined),
                    label: const Text('测试英文'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const AppPanel(
          icon: Icons.lock_outline,
          title: '隐私',
          child: Text('学宝不需要登录，不上传学习数据。错题、听写和成绩记录只保存在本机。'),
        ),
        const SizedBox(height: 12),
        const AppPanel(
          icon: Icons.info_outline,
          title: '版本',
          child: Text('学宝 0.1.0，本地 MVP 版本。'),
        ),
      ],
    );
  }

  Future<void> _speak(String language, String text) async {
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(0.48);
    await _tts.stop();
    await _tts.speak(text);
  }
}

class SubjectSelector extends StatelessWidget {
  const SubjectSelector({
    required this.value,
    required this.onChanged,
    this.subjects = Subject.values,
    super.key,
  });

  final Subject value;
  final List<Subject> subjects;
  final ValueChanged<Subject> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Subject>(
      segments: subjects
          .map(
            (subject) => ButtonSegment<Subject>(
              value: subject,
              icon: Icon(subject.icon),
              label: Text(subject.label),
            ),
          )
          .toList(),
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class GradeSelector extends StatelessWidget {
  const GradeSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 1, label: Text('一年级')),
        ButtonSegment(value: 2, label: Text('二年级')),
        ButtonSegment(value: 3, label: Text('三年级')),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          child: Icon(icon),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class AppPanel extends StatelessWidget {
  const AppPanel({
    required this.icon,
    required this.title,
    required this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
