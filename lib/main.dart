import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

Subject subjectFromImportValue(Object? value) {
  final key = '${value ?? ''}'.trim().toLowerCase();
  if (key == 'english' || key == 'en' || key == '英语' || key == '英文') {
    return Subject.english;
  }
  if (key == 'chinese' || key == 'cn' || key == '语文' || key == '中文') {
    return Subject.chinese;
  }
  return Subject.math;
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

class RewardProfile {
  const RewardProfile({
    required this.points,
    required this.completed,
    required this.perfect,
    required this.streak,
    required this.lastStudyDate,
  });

  final int points;
  final int completed;
  final int perfect;
  final int streak;
  final String lastStudyDate;

  int get level => points ~/ 100 + 1;
  int get currentLevelPoints => points % 100;
  String get title {
    if (level >= 10) {
      return '学习大师';
    }
    if (level >= 6) {
      return '闯关高手';
    }
    if (level >= 3) {
      return '进步之星';
    }
    return '学习新星';
  }

  Map<String, Object?> toJson() {
    return {
      'points': points,
      'completed': completed,
      'perfect': perfect,
      'streak': streak,
      'lastStudyDate': lastStudyDate,
    };
  }

  factory RewardProfile.fromJson(Map<String, Object?> json) {
    return RewardProfile(
      points: json['points'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      perfect: json['perfect'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      lastStudyDate: json['lastStudyDate'] as String? ?? '',
    );
  }

  static const empty = RewardProfile(points: 0, completed: 0, perfect: 0, streak: 0, lastStudyDate: '');
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

class AiHintSettings {
  const AiHintSettings({
    required this.dailyLimit,
  });

  final int dailyLimit;

  Map<String, Object?> toJson() {
    return {'dailyLimit': dailyLimit};
  }

  factory AiHintSettings.fromJson(Map<String, Object?> json) {
    return AiHintSettings(dailyLimit: json['dailyLimit'] as int? ?? 3);
  }

  static const defaults = AiHintSettings(dailyLimit: 3);
}

class AiConfig {
  const AiConfig({
    required this.enabled,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  final bool enabled;
  final String baseUrl;
  final String apiKey;
  final String model;

  bool get isReady => enabled && baseUrl.trim().isNotEmpty && apiKey.trim().isNotEmpty && model.trim().isNotEmpty;

  Map<String, Object?> toJson() {
    return {
      'enabled': enabled,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
    };
  }

  factory AiConfig.fromJson(Map<String, Object?> json) {
    return AiConfig(
      enabled: json['enabled'] as bool? ?? false,
      baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? 'gpt-4.1-mini',
    );
  }

  static const empty = AiConfig(
    enabled: false,
    baseUrl: 'https://api.openai.com/v1',
    apiKey: '',
    model: 'gpt-4.1-mini',
  );
}

class TtsApiConfig {
  const TtsApiConfig({
    required this.enabled,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.voice,
  });

  final bool enabled;
  final String baseUrl;
  final String apiKey;
  final String model;
  final String voice;

  bool get isReady =>
      enabled &&
      baseUrl.trim().isNotEmpty &&
      apiKey.trim().isNotEmpty &&
      model.trim().isNotEmpty &&
      voice.trim().isNotEmpty;

  Map<String, Object?> toJson() {
    return {
      'enabled': enabled,
      'baseUrl': baseUrl,
      'apiKey': apiKey,
      'model': model,
      'voice': voice,
    };
  }

  factory TtsApiConfig.fromJson(Map<String, Object?> json) {
    return TtsApiConfig(
      enabled: json['enabled'] as bool? ?? false,
      baseUrl: json['baseUrl'] as String? ?? 'https://api.openai.com/v1',
      apiKey: json['apiKey'] as String? ?? '',
      model: json['model'] as String? ?? 'gpt-4o-mini-tts',
      voice: json['voice'] as String? ?? 'alloy',
    );
  }

  static const empty = TtsApiConfig(
    enabled: false,
    baseUrl: 'https://api.openai.com/v1',
    apiKey: '',
    model: 'gpt-4o-mini-tts',
    voice: 'alloy',
  );
}

class LocalStore {
  static const _mistakesKey = 'xuebao_mistakes';
  static const _recordsKey = 'xuebao_records';
  static const _customQuestionsKey = 'xuebao_custom_questions';
  static const _customDictationKey = 'xuebao_custom_dictation';
  static const _aiConfigKey = 'xuebao_ai_config';
  static const _ttsApiConfigKey = 'xuebao_tts_api_config';
  static const _aiHintSettingsKey = 'xuebao_ai_hint_settings';
  static const _aiHintUsageDateKey = 'xuebao_ai_hint_usage_date';
  static const _aiHintUsageCountKey = 'xuebao_ai_hint_usage_count';
  static const _rewardKey = 'xuebao_rewards';

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

  static Future<AiConfig> loadAiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_aiConfigKey);
    if (raw == null || raw.isEmpty) {
      return AiConfig.empty;
    }
    return AiConfig.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
  }

  static Future<void> saveAiConfig(AiConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiConfigKey, jsonEncode(config.toJson()));
  }

  static Future<TtsApiConfig> loadTtsApiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ttsApiConfigKey);
    if (raw == null || raw.isEmpty) {
      return TtsApiConfig.empty;
    }
    return TtsApiConfig.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
  }

  static Future<void> saveTtsApiConfig(TtsApiConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ttsApiConfigKey, jsonEncode(config.toJson()));
  }

  static Future<AiHintSettings> loadAiHintSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_aiHintSettingsKey);
    if (raw == null || raw.isEmpty) {
      return AiHintSettings.defaults;
    }
    return AiHintSettings.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
  }

  static Future<void> saveAiHintSettings(AiHintSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiHintSettingsKey, jsonEncode(settings.toJson()));
  }

  static Future<int> loadTodayAiHintCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getString(_aiHintUsageDateKey) != today) {
      await prefs.setString(_aiHintUsageDateKey, today);
      await prefs.setInt(_aiHintUsageCountKey, 0);
      return 0;
    }
    return prefs.getInt(_aiHintUsageCountKey) ?? 0;
  }

  static Future<int> useAiHint() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final current = await loadTodayAiHintCount();
    await prefs.setString(_aiHintUsageDateKey, today);
    await prefs.setInt(_aiHintUsageCountKey, current + 1);
    return current + 1;
  }

  static Future<RewardProfile> loadRewards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rewardKey);
    if (raw == null || raw.isEmpty) {
      return RewardProfile.empty;
    }
    return RewardProfile.fromJson(Map<String, Object?>.from(jsonDecode(raw) as Map));
  }

  static Future<RewardProfile> addReward({required int score, required int total}) async {
    final current = await loadRewards();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final nextStreak = current.lastStudyDate == today
        ? current.streak
        : current.lastStudyDate == yesterday
            ? current.streak + 1
            : 1;
    final earned = 10 + (score ~/ 10) + (total >= 10 ? 5 : 0) + (score == 100 ? 15 : 0);
    final next = RewardProfile(
      points: current.points + earned,
      completed: current.completed + 1,
      perfect: current.perfect + (score == 100 ? 1 : 0),
      streak: nextStreak,
      lastStudyDate: today,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rewardKey, jsonEncode(next.toJson()));
    return next;
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

class AppTtsService {
  AppTtsService();

  final _apiPlayer = AudioPlayer();
  bool _disposed = false;

  Future<void> speak({
    required String text,
    required bool slow,
  }) async {
    if (_disposed) {
      return;
    }

    await stop();
    final config = await LocalStore.loadTtsApiConfig();
    if (!config.isReady) {
      throw const FormatException('请先到设置里启用并填写 OpenAI 格式 TTS API。');
    }
    await _speakWithApi(config: config, text: text, slow: slow);
  }

  Future<void> stop() async {
    await _apiPlayer.stop();
  }

  Future<void> speakWithApiOnly({
    required TtsApiConfig config,
    required String text,
    required bool slow,
  }) async {
    await stop();
    if (!config.isReady) {
      throw const FormatException('请先启用并填写完整的 TTS API 配置。');
    }
    await _speakWithApi(config: config, text: text, slow: slow);
  }

  void dispose() {
    _disposed = true;
    unawaited(_apiPlayer.dispose());
  }

  Future<void> _speakWithApi({
    required TtsApiConfig config,
    required String text,
    required bool slow,
  }) async {
    final endpoint = Uri.parse('${config.baseUrl.replaceAll(RegExp(r'/+$'), '')}/audio/speech');
    final voice = resolveTtsVoice(config);
    final response = await http
        .post(
          endpoint,
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': config.model,
            'voice': voice,
            'input': text,
            'response_format': 'mp3',
            'speed': slow ? 0.85 : 1.0,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException('TTS API 返回 ${response.statusCode}：${response.body}');
    }

    final completed = _apiPlayer.onPlayerComplete.first;
    await _apiPlayer.play(BytesSource(response.bodyBytes));
    await completed.timeout(Duration(seconds: max(15, text.length * 3)));
  }
}

class AiHintService {
  static Future<String> createHint({
    required AiConfig config,
    required PracticeQuestion question,
  }) async {
    if (!config.isReady) {
      throw const FormatException('请先在设置中开启并填写 AI API 渠道。');
    }

    final endpoint = Uri.parse('${config.baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions');
    final response = await http
        .post(
          endpoint,
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': config.model,
            'messages': [
              {
                'role': 'system',
                'content': '你是小学生学习助手。只给解题提示，不许直接说出最终答案，不许列出完整计算结果。控制在 60 字以内。',
              },
              {
                'role': 'user',
                'content': '科目：${question.subject.label}\n年级：${question.grade}\n题目：${question.question}\n请给一个小提示，不能透露答案。',
              },
            ],
            'temperature': 0.4,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException('AI 提示接口返回 ${response.statusCode}：${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    final message = choices == null || choices.isEmpty ? null : choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content.trim();
    }
    throw const FormatException('AI 没有返回可用提示。');
  }
}

String resolveTtsVoice(TtsApiConfig config) {
  final voice = config.voice.trim();
  final model = config.model.trim();
  final baseUrl = config.baseUrl.toLowerCase();
  if (baseUrl.contains('siliconflow') && !voice.contains(':') && model.isNotEmpty) {
    return '$model:$voice';
  }
  return voice;
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

class EnglishWord {
  const EnglishWord({
    required this.word,
    required this.meaning,
    required this.partOfSpeech,
    required this.category,
    required this.grade,
  });

  final String word;
  final String meaning;
  final String partOfSpeech;
  final String category;
  final int grade;
}

class WordStudyItem {
  const WordStudyItem({
    required this.word,
    required this.meaning,
    required this.partOfSpeech,
    required this.category,
  });

  final String word;
  final String meaning;
  final String partOfSpeech;
  final String category;
}

final questionBank = buildQuestionBank();
final dictationBank = buildDictationBank();

const chineseWordsByGrade = <int, List<String>>{
  1: [
    '一二', '第一', '二胡', '二月', '三天', '三个', '上下', '上车',
    '人口', '出口', '目光', '目的', '木耳', '耳朵', '手机', '双手',
    '日子', '日月', '田野', '田地', '禾田', '禾苗', '火车', '上火',
    '害虫', '虫子', '白云', '乌云', '大山', '山羊', '八个', '八天',
    '十个', '十天', '走了', '来了', '子女', '子孙', '亲人', '大小',
    '大人', '月牙', '月亮', '儿子', '少儿', '开头', '头顶', '里面',
    '里外', '可口', '认可', '东西', '东方', '西瓜', '西方', '今天',
    '天地', '四周', '四面', '不是', '可是', '女儿', '母女', '开心',
    '开水', '水果', '热水', '出去', '回去', '来往', '来电', '不行',
    '不能', '小孩', '小米', '多少', '少见', '牛羊', '牛毛', '瓜果',
    '小鸟', '飞鸟', '早上', '早晨', '书本', '书包', '大刀', '飞刀',
    '尺子', '米尺', '课本', '本子', '木头', '树木', '森林', '山林',
    '泥土', '土地', '力量', '电力', '心情', '中文', '中心', '五天',
    '五年', '立正', '自立', '公正', '正门', '正在', '不在', '后果',
    '后来', '我们', '我的', '好人', '好事', '长短', '长江', '比较',
    '比如', '巴士', '大巴', '把手', '车把', '下车', '几个', '个人',
    '雨水', '下雨', '他们', '她们', '问好', '学问', '有无', '没有',
    '一半', '半天', '从前', '从来', '你们', '你好', '才能', '天才',
    '明天', '明白', '同伴', '同学', '放学', '学习', '自己', '自大',
    '身不由己', '毛衣', '大衣', '白天', '空白', '好的', '是的', '又来',
    '又是', '和平', '和气', '竹子', '竹叶', '牙齿', '牙印', '马车',
    '木马', '用心', '用力', '几天', '一只', '只身', '石头', '石子',
    '多年', '日出', '出来', '见面', '再见', '对面', '对立', '妈妈',
    '姨妈', '全部', '齐全', '回家', '工人', '工作', '厂房', '厂长',
    '蓝天', '天空', '大地', '地球', '人们', '人民', '他人', '单一',
    '二十', '十二', '三十', '三月', '四十', '四月', '十五', '五彩',
    '上午', '上山', '下班', '下去', '口水', '耳机', '目录', '手脚',
    '小手', '足球', '手足', '站立',
  ],
  2: [
    '两个', '两人', '就是', '成就', '哪里', '哪个', '宽大', '宽广',
    '头顶', '屋顶', '目不转睛', '肚子', '肚量', '毛皮', '羊皮', '孩子',
    '男孩', '跳远', '跳高', '变化', '改变', '南极', '极地', '一片',
    '叶片', '傍晚', '依傍', '海洋', '大海', '大洋', '作文', '作业',
    '坏人', '好坏', '送给', '交给', '皮带', '带领', '加法', '办法',
    '如果', '如此', '脚步', '山脚', '它们', '其它', '女娃', '娃娃',
    '她们', '她的', '羊毛', '皮毛', '更好', '更加', '知识', '知道',
    '识字', '识别', '果园', '校园', '毛孔', '鼻孔', '大桥', '石桥',
    '羊群', '人群', '军队', '队长', '红旗', '彩旗', '铜钱', '铜铁',
    '句号', '号码', '领队', '毛巾', '围巾', '杨树', '杨柳', '强壮',
    '壮丽', '梧桐', '桐花', '枫叶', '枫树', '松树', '松鼠', '柏树',
    '松柏', '棉花', '木棉', '水杉', '杉树', '文化', '桂树', '桂林',
    '唱歌', '歌曲', '丛林', '一丛', '深浅', '深入', '到处', '好处',
    '六天', '六月', '熊猫', '黑熊', '小猫', '花猫', '九点', '九月',
    '朋友', '亲朋', '友好', '亲友', '四季', '春季', '吹风', '吹动',
    '肥胖', '肥料', '农业', '农民', '帮忙', '连忙', '回归', '归队',
    '佩戴', '爱戴', '辛苦', '辛劳', '苦瓜', '苦味', '今年', '年月',
    '称重', '称呼', '柱子', '水柱', '海底', '底下', '杆秤', '枪杆',
    '秤砣', '秤锤', '做客', '做法', '岁月', '岁数', '车站', '站立',
    '龙船', '游船', '当然', '自然', '画面', '图画', '幅度', '振幅',
    '评奖', '评价', '奖品', '奖金', '守候', '等候', '报告', '报纸',
    '另外', '另有', '及时', '及早', '拿到', '捉拿', '并且', '并非',
    '信封', '封面', '信心', '相信', '今天', '今后', '写字', '书写',
    '支付', '支持', '圆形', '圆心', '珠宝', '珍珠', '笔记', '铅笔',
    '灯光', '台灯', '电灯', '电脑', '哄人', '哄骗', '先生', '先后',
    '闭嘴', '关闭', '脸面', '脸色', '事情', '事故', '沉重', '沉默',
    '发型', '白发', '窗户', '门窗', '高楼', '上楼', '依法', '依靠',
    '尽力', '尽心', '黄色', '黄河',
  ],
  3: [
    '早晨', '晨练', '绒毛', '绒花', '足球', '地球', '汉字', '汉族',
    '艳丽', '鲜艳', '西服', '服务', '服装', '装饰', '扮演', '装扮',
    '读者', '阅读', '安静', '静止', '停车', '暂停', '粗糙', '粗壮',
    '影子', '电影', '落泪', '落叶', '荒唐', '笛子', '汽笛', '荒凉',
    '跳舞', '舞蹈', '狂风', '狂野', '罚款', '惩罚', '请假', '假期',
    '互相', '互动', '所以', '场所', '足够', '够本', '猜谜', '猜想',
    '飞扬', '发扬', '手臂', '臂膀', '寒冷', '寒冬', '半径', '捷径',
    '斜坡', '倾斜', '霜冻', '霜降', '赠送', '赠品', '刘海', '姓刘',
    '瓶盖', '井盖', '菊花', '墨菊', '残疾', '摧残', '君主', '君子',
    '橙子', '橙汁', '送别', '送礼', '挑食', '挑水', '铺路', '铺张',
    '泥土', '泥泞', '水晶', '晶莹', '紧张', '紧急', '医院', '法院',
    '脚印', '印刷', '排队', '排练', '列车', '列举', '圆规', '规则',
    '法则', '准则', '凌乱', '扰乱', '棕熊', '棕色', '迟到', '迟早',
    '盒饭', '纸盒', '颜色', '颜料', '照料', '资料', '车票', '发票',
    '飘扬', '飘动', '争斗', '争取', '仙女', '仙境', '新闻', '耳闻',
    '梨花', '梨树', '勾画', '勾引', '石油', '油条', '曲调', '歌曲',
    '丰收', '丰富', '火柴', '木柴', '冷淡', '怀旧', '念旧', '围裙',
    '短裙', '可怜', '怜爱', '饥饿', '挨饿', '几乎', '似乎', '火焰',
    '气焰', '蜡笔', '腊梅', '烛光', '蜡烛', '富贵', '富强', '诉苦',
    '诉说', '离开', '离别', '旅游', '旅客', '咱们', '救命', '救援',
    '命令', '生命', '拼搏', '拼凑', '扫地', '扫兴', '胃口', '肠胃',
    '水管', '管理', '等待', '等级', '刚好', '阳刚', '流行', '流动',
    '泪水', '眼泪', '口算', '算盘', '山洞', '漏洞', '准备', '准确',
    '防备', '备份', '暴发', '暴雨', '墙壁', '墙边', '壁虎', '壁画',
    '砍柴', '砍价', '蜘蛛', '蛛网', '蛛丝马迹', '漂亮', '撞击', '碰撞',
    '饱满', '饱餐', '晾晒', '日晒', '搭配', '搭车', '亲近', '亲人',
    '父爱', '神父', '沙发', '沙漠', '哗啦', '啦啦队', '响声', '响亮',
    '羽毛', '羽绒', '翠绿', '翠鸟',
  ],
  4: [
    '潮水', '潮湿', '据说', '根据', '河堤', '堤岸', '开阔', '广阔',
    '盼望', '期盼', '滚动', '翻滚', '顿时', '停顿', '逐渐', '追逐',
    '渐变', '堵车', '堵塞', '犹如', '犹豫', '雪崩', '崩溃', '震撼',
    '地震', '霎时', '一霎', '剩余', '业余', '淘米', '淘金', '牵手',
    '牵连', '鹅蛋', '鹅肉', '卵巢', '卵子', '坑洞', '洼地', '低洼',
    '填补', '填写', '庄园', '庄稼', '俗气', '低俗', '雀跃', '葡萄',
    '跳跃', '稻田', '成熟', '水稻', '熟练', '豌豆', '按时', '按照',
    '舒适', '舒服', '适合', '恐龙', '恐惧', '僵硬', '僵局', '硬币',
    '硬件', '枪声', '手枪', '耐心', '忍耐', '探险', '侦探', '愉悦',
    '愉快', '曾经', '不曾', '到达', '表达', '蚊子', '蚊虫', '即使',
    '立即', '科举', '科考', '横批', '横线', '竖琴', '横竖', '绳子',
    '绳索', '系紧', '系住', '蝇虫', '果蝇', '证明', '证人', '研究',
    '科研', '追究', '究竟', '驾照', '行驶', '驾驶', '驶向', '唤醒',
    '呼唤', '纪律', '记录', '技术', '技能', '修改', '改革', '程度',
    '行程', '超级', '超市', '亿万', '亿元', '核心', '核能', '奥秘',
    '深奥', '益智', '效益', '联合', '联系', '质量', '本质', '哲学',
    '哲理', '任何', '责任', '善良', '友善', '迟暮', '暮年', '吟唱',
    '吟诵', '题目', '试题', '侧重', '侧面', '峰顶', '山峰', '茅庐',
    '庐山', '缘分', '缘故', '投降', '诱降', '阁下', '楼阁', '浪费',
    '免费', '必须', '胡须', '逊色', '谦逊', '运输', '输入', '老虎',
    '壁虎', '操作', '操场', '占领', '占据', '娇嫩', '嫩芽', '顺利',
    '柔顺', '均匀', '平均', '折叠', '重叠', '缝隙', '嫌隙', '根茎',
    '茎叶', '把柄', '手柄', '萎缩', '枯萎', '瞧见', '小瞧', '固定',
    '坚固', '宅子', '宅院', '临时', '来临', '慎重', '谨慎', '挑选',
    '选项', '选择', '择优', '地址', '住址', '良心', '良好', '洞穴',
    '穴位', '餐厅', '客厅', '卧室', '卧底', '专业', '专长', '尺寸',
    '英寸', '保卫', '卫生', '比较', '较量', '翻腾', '劈头盖脸', '缓慢',
    '缓解', '浑浊', '污浊', '丈量',
  ],
  5: [
    '适宜', '宜居', '仙鹤', '野鹤', '嫌弃', '嫌疑', '朱熹', '朱红',
    '镶嵌', '嵌入', '相框', '框架', '匣子', '暗匣', '放哨', '吹哨',
    '恩情', '恩惠', '韵律', '韵脚', '田亩', '一亩', '播放', '广播',
    '浇灌', '浇水', '吩咐', '嘱咐', '亭台', '亭子', '榨汁', '压榨',
    '羡慕', '仰慕', '矮小', '高矮', '懂事', '懂得', '兰花', '兰草',
    '箩筐', '稻箩', '外婆', '巫婆', '糕点', '蛋糕', '饼干', '月饼',
    '浸染', '沉浸', '缠绕', '纠缠', '茶叶', '茶水', '捡漏', '捡起',
    '潮汛', '汛情', '访问', '访谈', '鞋子', '鞋带', '挽救', '挽回',
    '阻隔', '隔绝', '懒散', '懒虫', '惰性', '懒惰', '稳定', '平稳',
    '衡量', '平衡', '协议', '协商', '号召', '召唤', '罪臣', '奸臣',
    '议论', '商议', '宫殿', '皇宫', '奉献', '贡献', '许诺', '诺言',
    '典型', '典礼', '抄袭', '抄写', '犯罪', '罪恶', '拒绝', '拒收',
    '负荆请罪', '荆棘', '胆怯', '羞怯', '冠军', '冠名', '俯视', '俯瞰',
    '喷射', '喷泉', '不胜枚举', '一枚', '箭头', '火箭', '万花筒', '甜筒',
    '结束', '花束', '赤膊', '赤道', '圆圈', '圈套', '装置', '设置',
    '入侵', '侵略', '省略', '忽略', '建筑', '筑造', '碉堡', '城堡',
    '党派', '政党', '山丘', '丘陵', '妨碍', '无妨', '遮蔽', '隐蔽',
    '陷阱', '沦陷', '拐卖', '拐角', '应酬', '酬宾', '珍贵', '珍藏',
    '叮嘱', '叮咛', '嘱托', '坍塌', '塌陷', '焦虑', '焦急', '誓言',
    '发誓', '说谎', '谎言', '延迟', '延期', '后悔', '悔恨', '帮扶',
    '扶手', '郎君', '郎中', '干爹', '爹娘', '嫂子', '大嫂', '车辆',
    '好歹', '歹徒', '人迹罕至', '罕见', '纱巾', '纱布', '妻子', '妻儿',
    '一趟', '赶趟', '托付', '托举', '游泳', '冬泳', '婚姻', '结婚',
    '祖辈', '辈分', '挨边', '挨近', '祭拜', '祭奠', '乃是', '乃至',
    '熏陶', '熏染', '杭州', '苏杭', '亥时', '恃宠而骄', '自恃', '哀求',
    '悲哀', '拘谨', '拘束', '节选', '倾泻', '泻药', '潜伏', '潜入',
    '考试', '测试', '轮胎', '胎儿', '皇帝', '皇上', '履行', '履历',
    '疆土', '边疆', '毁灭', '摧毁',
  ],
  6: [
    '毛毯', '毯子', '陈旧', '陈皮', '衣裳', '彩虹', '霓虹', '猪蹄',
    '马蹄', '腐烂', '腐蚀', '稍等', '稍微', '微笑', '微风', '点缀',
    '前缀', '幽香', '幽静', '优雅', '文雅', '案件', '答案', '笨拙',
    '拙劣', '单薄', '薄利', '迷糊', '模糊', '花蕾', '蓓蕾', '衣襟',
    '襟怀', '恍然', '恍惚', '怨恨', '埋怨', '道德', '美德', '喜鹊',
    '鹊桥', '蝉鸣', '蝉联', '悬崖', '山崖', '渡口', '轮渡', '绳索',
    '索要', '倭寇', '敌寇', '副业', '副词', '榴弹', '榴莲', '子弹',
    '导弹', '抡锤', '抡起', '连贯', '贯通', '下棋', '棋子', '悬挂',
    '沸水', '沸腾', '山涧', '深涧', '冰雹', '雹子', '屹立', '屹然',
    '悦耳', '喜悦', '委屈', '屈服', '政治', '政府', '宾客', '宾馆',
    '灯盏', '一盏', '栏杆', '栏目', '汇聚', '汇集', '爆炸', '火爆',
    '宣传', '宣布', '旗帜', '易帜', '阅读', '检阅', '隆重', '隆冬',
    '制约', '制度', '坦白', '平坦', '距离', '差距', '射击', '射箭',
    '豁然', '豁达', '凛然', '凛冽', '疙瘩', '疙疤', '疙疙瘩瘩', '棍棒',
    '电棍', '裁缝', '剪裁', '筹集', '筹款', '橡皮', '橡胶', '雕刻',
    '雕塑', '跺脚', '跺足', '颓废', '颓然', '沮丧', '沮愤', '趴着',
    '趴下', '抽屉', '屉子', '谜语', '谜底', '高尚', '尚且', '氧气',
    '缺氧', '倾斜', '倾听', '揭晓', '揭示', '斑马', '斑驳', '燥热',
    '干燥', '冷漠', '漠然', '磁铁', '磁场', '抵挡', '抵抗', '御用',
    '御厨', '素材', '素质', '偷盗', '盗窃', '培养', '培育', '咆哮',
    '咆号', '哮喘', '嗓音', '嗓子', '流淌', '淌下', '哑巴', '沙哑',
    '揪出', '揪心', '呻吟', '呻呼', '废品', '废除', '汹涌', '汹汹',
    '涌现', '喷涌', '澎湃', '澎澎', '滂湃', '熄灭', '熄火', '掀起',
    '掀翻', '困惑', '困扰', '淋雨', '淋浴', '嘿嘿', '糟糕', '糟粕',
    '对嘛', '皱纹', '褶皱', '勺子', '汤勺', '大棚', '顶棚', '苔藓',
    '海苔', '青藓', '草坪', '坪坝', '甘蔗', '蔗糖', '瀑布', '飞瀑',
    '增加', '增多', '缝隙', '裂缝', '谚语', '农谚', '衣袖', '袖子',
    '篷车', '船篷', '缩小', '缩减',
  ],
};

const englishVocabularyRaw = r'''
01第一类：动物
bear 熊 n.
rabbit 兔子 n.
mouse 老鼠 n.
cat 猫 n.
dog 狗 n.
horse 马 n.
pig 猪 n.
cow 奶牛 n.
sheep 绵羊 n.
lion 狮子 n.
tiger 老虎 n.
panda 熊猫 n.
elephant 大象 n.
monkey 猴子 n.
zebra 斑马 n.
bird 鸟 n.
duck 鸭子 n.
chicken 鸡 n.
ant 蚂蚁 n.
bee 蜜蜂 n.
butterfly 蝴蝶 n.
dragonfly 蜻蜓 n.
firefly 萤火虫 n.
grasshopper 蚱蜢 n.
cicada 蝉 n.
cricket 蟋蟀 n.
fish 鱼 n.
frog 青蛙 n.
snake 蛇 n.
turtle 乌龟 n.
goat 山羊 n.
donkey 驴 n.
fox 狐狸 n.
wolf 狼 n.
deer 鹿 n.
camel 骆驼 n.
kangaroo 袋鼠 n.
penguin 企鹅 n.
whale 鲸 n.
dolphin 海豚 n.
shark 鲨鱼 n.
octopus 章鱼 n.
spider 蜘蛛 n.
snail 蜗牛 n.
worm 蚯蚓 n.
fly 苍蝇 n.
mosquito 蚊子 n.
ladybird 瓢虫 n.
bat 蝙蝠 n.
owl 猫头鹰 n.
eagle 老鹰 n.
parrot 鹦鹉 n.
hen 母鸡 n.
rooster 公鸡 n.
turkey 火鸡 n.
goose 鹅 n.
swan 天鹅 n.
seal 海豹 n.
yak 牦牛 n.
ox 公牛 n.

02第二类：植物 & 自然
plant 植物 n.
tree 树 n.
flower 花 n.
leaf 叶子 n.
grass 草 n.
seed 种子 n.
sprout 幼苗 n.
rose 玫瑰 n.
forest 森林 n.
river 河流 n.
lake 湖泊 n.
stream 小溪 n.
mountain 山 n.
hill 小山 n.
sky 天空 n.
sun 太阳 n.
moon 月亮 n.
star 星星 n.
rain 雨 n.
snow 雪 n.
wind 风 n.
cloud 云 n.
rainbow 彩虹 n.
air 空气 n.
stone 石头 n.
sand 沙子 n.
soil 土壤 n.
path 小路 n.
road 公路 n.
bridge 桥 n.
field 田野 n.
beach 海滩 n.
sea 海 n.
ocean 海洋 n.
island 岛屿 n.
water 水 n.
fire 火 n.
wood 木头 n.
leafy 多叶的 adj.
green 绿色的 adj.
fresh 新鲜的 adj.
natural 自然的 adj.
wet 潮湿的 adj.
dry 干燥的 adj.
hot 炎热的 adj.
cold 寒冷的 adj.
cool 凉爽的 adj.
warm 温暖的 adj.
sunny 晴朗的 adj.
rainy 下雨的 adj.
snowy 下雪的 adj.
windy 有风的 adj.
cloudy 多云的 adj.
storm 暴风雨 n.
weather 天气 n.
season 季节 n.
spring 春天 n.
summer 夏天 n.
autumn 秋天 n.
winter 冬天 n.
climate 气候 n.

03第三类：食物 & 饮品
rice 米饭 n.
noodles 面条 n.
bread 面包 n.
cake 蛋糕 n.
cookie 饼干 n.
chocolate 巧克力 n.
ice cream 冰淇淋 n.
hamburger 汉堡 n.
sandwich 三明治 n.
hot dog 热狗 n.
pizza 披萨 n.
soup 汤 n.
salad 沙拉 n.
meat 肉 n.
beef 牛肉 n.
pork 猪肉 n.
egg 鸡蛋 n.
milk 牛奶 n.
juice 果汁 n.
tea 茶 n.
coffee 咖啡 n.
cola 可乐 n.
fruit 水果 n.
apple 苹果 n.
banana 香蕉 n.
orange 橙子 n.
pear 梨 n.
peach 桃子 n.
grape 葡萄 n.
watermelon 西瓜 n.
pineapple 菠萝 n.
mango 芒果 n.
strawberry 草莓 n.
vegetable 蔬菜 n.
tomato 西红柿 n.
potato 土豆 n.
carrot 胡萝卜 n.
cabbage 卷心菜 n.
onion 洋葱 n.
bean 豆子 n.
pumpkin 南瓜 n.
corn 玉米 n.
breakfast 早餐 n.
lunch 午餐 n.
dinner 晚餐 n.
meal 一餐 n.
sweet 糖果 n.
jam 果酱 n.
butter 黄油 n.
oil 食用油 n.
salt 盐 n.
sugar 糖 n.
knife 刀 n.
fork 叉 n.
spoon 勺 n.
plate 盘子 n.
bowl 碗 n.
cup 杯子 n.
bottle 瓶子 n.

04第四类：人体部位 & 健康
head 头 n.
hair 头发 n.
face 脸 n.
eye 眼睛 n.
ear 耳朵 n.
nose 鼻子 n.
mouth 嘴 n.
tooth 牙齿 n.
neck 脖子 n.
shoulder 肩膀 n.
arm 手臂 n.
hand 手 n.
finger 手指 n.
leg 腿 n.
knee 膝盖 n.
foot 脚 n.
toe 脚趾 n.
back 背部 n.
body 身体 n.
tail 尾巴 n.
hurt 疼 v.
ache 疼痛 n./v.
fever 发烧 n.
cold 感冒 n.
cough 咳嗽 n./v.
headache 头疼 n.
toothache 牙疼 n.
earache 耳朵疼 n.
stomachache 胃痛 n.
ill 生病的 adj.
sick 生病的 adj.
healthy 健康的 adj.
weak 虚弱的 adj.
strong 强壮的 adj.
tired 累的 adj.
hungry 饿的 adj.
thirsty 渴的 adj.
hot 热的 adj.
doctor 医生 n.
nurse 护士 n.
hospital 医院 n.
medicine 药 n.
pill 药片 n.
rest 休息 v./n.
sleep 睡觉 v.
exercise 锻炼 n./v.
check 检查 v.
care 照顾 n./v.
feel 感觉 v.
pain 疼痛 n.
health 健康 n.
recover 恢复 v.

05第五类：学习用品 & 校园
school 学校 n.
class 班级 n.
classroom 教室 n.
teacher 老师 n.
student 学生 n.
desk 课桌 n.
chair 椅子 n.
blackboard 黑板 n.
book 书 n.
notebook 笔记本 n.
schoolbag 书包 n.
pen 钢笔 n.
pencil 铅笔 n.
eraser 橡皮 n.
ruler 尺子 n.
crayon 蜡笔 n.
marker 记号笔 n.
sharpener 卷笔刀 n.
paper 纸 n.
dictionary 词典 n.
homework 作业 n.
lesson 课 n.
test 测试 n.
exam 考试 n.
subject 科目 n.
English 英语 n.
Chinese 语文 n.
Maths 数学 n.
Music 音乐 n.
Art 美术 n.
PE 体育 n.
Science 科学 n.
Computer 电脑 n.
library 图书馆 n.
office 办公室 n.
playground 操场 n.
reading room 阅览室 n.
music room 音乐教室 n.
computer room 电脑教室 n.
noticeboard 公告栏 n.
teacher's desk 讲台 n.
read 读 v.
write 写 v.
listen 听 v.
learn 学习 v.
study 学习 v.
answer 回答 v.
ask 问 v.
spell 拼写 v.
copy 抄写 v.
draw 画 v.
open 打开 v.
close 关闭 v.

06第六类：家居 & 房间
house 房子 n.
home 家 n.
room 房间 n.
bedroom 卧室 n.
living room 客厅 n.
bathroom 浴室 n.
kitchen 厨房 n.
study 书房 n.
toilet 厕所 n.
bed 床 n.
table 桌子 n.
chair 椅子 n.
sofa 沙发 n.
desk 书桌 n.
lamp 灯 n.
light 灯 n.
door 门 n.
window 窗户 n.
wall 墙 n.
floor 地板 n.
mirror 镜子 n.
fridge 冰箱 n.
TV 电视 n.
radio 收音机 n.
computer 电脑 n.
telephone 电话 n.
fan 风扇 n.
air-conditioner 空调 n.
clock 钟 n.
watch 手表 n.
chopsticks 筷子 n.
clean 打扫 v.
wash 洗 v.
cook 做饭 v.

07第七类：交通 & 地点
car 小汽车 n.
bus 公交车 n.
bike 自行车 n.
train 火车 n.
plane 飞机 n.
ship 轮船 n.
boat 小船 n.
taxi 出租车 n.
subway 地铁 n.
jeep 吉普车 n.
van 面包车 n.
street 街道 n.
station 车站 n.
airport 机场 n.
stop 站点 n.
park 公园 n.
zoo 动物园 n.
cinema 电影院 n.
shop 商店 n.
supermarket 超市 n.
bank 银行 n.
post office 邮局 n.
city 城市 n.
town 城镇 n.
village 乡村 n.
country 国家 n.
China 中国 n.
England 英国 n.
America 美国 n.
Japan 日本 n.
go 去 v.
come 来 v.
walk 走 v.
run 跑 v.
drive 开车 v.
ride 骑 v.
travel 旅行 v.
visit 参观 v.

08第八类：高频动词
go 去 v.
come 来 v.
do 做 v.
make 制作 v.
get 得到 v.
have 有 v.
take 拿 v.
give 给 v.
put 放 v.
bring 带来 v.
eat 吃 v.
drink 喝 v.
sleep 睡 v.
read 读 v.
write 写 v.
listen 听 v.
speak 说 v.
say 说 v.
tell 告诉 v.
ask 问 v.
play 玩 v.
run 跑 v.
walk 走 v.
jump 跳 v.
climb 爬 v.
swim 游泳 v.
fly 飞 v.
see 看见 v.
watch 看 v.
look 看 v.
hear 听见 v.
feel 感觉 v.
help 帮助 v.
learn 学习 v.
study 学习 v.
work 工作 v.
clean 打扫 v.
wash 洗 v.
cook 做饭 v.
buy 买 v.
sell 卖 v.
start 开始 v.
finish 完成 v.
stop 停止 v.

09第九类：形容词 & 感受
big 大的 adj.
small 小的 adj.
long 长的 adj.
short 短的 adj.
tall 高的 adj.
fat 胖的 adj.
thin 瘦的 adj.
old 老的 adj.
young 年轻的 adj.
new 新的 adj.
good 好的 adj.
bad 坏的 adj.
fine 好的 adj.
great 很好的 adj.
happy 开心的 adj.
sad 难过的 adj.
angry 生气的 adj.
tired 累的 adj.
busy 忙的 adj.
free 空闲的 adj.
hot 热的 adj.
cold 冷的 adj.
warm 温暖的 adj.
cool 凉爽的 adj.
easy 简单的 adj.
hard 困难的 adj.
fast 快的 adj.
slow 慢的 adj.
beautiful 美丽的 adj.
cute 可爱的 adj.
lovely 可爱的 adj.
ugly 丑的 adj.
dirty 脏的 adj.
interesting 有趣的 adj.
boring 无聊的 adj.
funny 好笑的 adj.
quiet 安静的 adj.
noisy 吵闹的 adj.
favourite 最喜欢的 adj.

10第十类：数词 / 时间 / 疑问词
one 一 num.
two 二 num.
three 三 num.
four 四 num.
five 五 num.
six 六 num.
seven 七 num.
eight 八 num.
nine 九 num.
ten 十 num.
eleven 十一 num.
twelve 十二 num.
thirteen 十三 num.
twenty 二十 num.
thirty 三十 num.
forty 四十 num.
fifty 五十 num.
hundred 一百 num.
first 第一 adj.
second 第二 adj.
third 第三 adj.
today 今天 n.
tomorrow 明天 n.
yesterday 昨天 n.
morning 早晨 n.
afternoon 下午 n.
evening 晚上 n.
night 夜晚 n.
week 周 n.
weekend 周末 n.
what 什么 pron.
who 谁 pron.
where 哪里 adv.
when 什么时候 adv.
why 为什么 adv.
how 怎样 adv.
how many 多少 phrase.
how much 多少钱 phrase.
what time 几点 phrase.
which 哪一个 pron.
''';

final englishVocabulary = buildEnglishVocabulary();
final englishWordsByGrade = buildEnglishWordsByGrade();

List<EnglishWord> buildEnglishVocabulary() {
  final categoryMatches = RegExp(r'(\d{2})第.+?类：([^\n]+)').allMatches(englishVocabularyRaw).toList();
  final entryPattern = RegExp(
    r"([A-Za-z][A-Za-z'\-\s]*?)\s+([\u4e00-\u9fff，/]+)\s+(n\./v\.|v\./n\.|adj\.|adv\.|pron\.|num\.|phrase\.|n\.|v\.)",
  );
  final words = <EnglishWord>[];
  final seen = <String>{};

  for (final match in entryPattern.allMatches(englishVocabularyRaw)) {
    final category = _categoryForOffset(categoryMatches, match.start);
    final word = match.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
    final key = word.toLowerCase();
    if (seen.contains(key)) {
      continue;
    }
    seen.add(key);
    words.add(
      EnglishWord(
        word: word,
        meaning: match.group(2)!.trim(),
        partOfSpeech: match.group(3)!.trim(),
        category: category.name,
        grade: category.grade,
      ),
    );
  }

  return words;
}

({String name, int grade}) _categoryForOffset(List<RegExpMatch> matches, int offset) {
  var name = '英语词汇';
  var number = 1;
  for (final match in matches) {
    if (match.start > offset) {
      break;
    }
    number = int.parse(match.group(1)!);
    name = match.group(2)!.trim();
  }
  return (name: name, grade: _gradeForEnglishCategory(number));
}

int _gradeForEnglishCategory(int category) {
  if (category <= 1) {
    return 1;
  }
  if (category <= 3) {
    return 2;
  }
  if (category <= 5) {
    return 3;
  }
  if (category <= 7) {
    return 4;
  }
  if (category <= 9) {
    return 5;
  }
  return 6;
}

Map<int, Map<String, String>> buildEnglishWordsByGrade() {
  final wordsByGrade = {for (var grade = 1; grade <= 6; grade++) grade: <String, String>{}};
  for (final item in englishVocabulary) {
    wordsByGrade[item.grade]![item.word] = item.meaning;
  }
  return wordsByGrade;
}

List<DictationItem> buildDictationBank() {
  final items = <DictationItem>[];
  chineseWordsByGrade.forEach((grade, words) {
    for (var i = 0; i < words.length; i++) {
      items.add(DictationItem(id: 'cn_${grade}_$i', subject: Subject.chinese, grade: grade, text: words[i], hint: '', sentence: '语文常用词。'));
    }
  });
  englishWordsByGrade.forEach((grade, words) {
    var i = 0;
    words.forEach((word, hint) {
      items.add(DictationItem(id: 'en_${grade}_${i++}', subject: Subject.english, grade: grade, text: word, hint: hint, sentence: hint));
    });
  });
  return items;
}

List<PracticeQuestion> buildQuestionBank() {
  final questions = <PracticeQuestion>[];
  for (var grade = 1; grade <= 6; grade++) {
    if (grade == 1) {
      addFirstGradeMathQuestions(questions);
    } else {
      for (var i = 1; i <= 100; i++) {
        final a = grade * 3 + i;
        final b = grade + i % 9 + 1;
        final answer = grade <= 2 ? a + b : (i.isEven ? a * b : a + b * grade);
        final expression = grade <= 2 ? '$a + $b' : (i.isEven ? '$a × $b' : '$a + $b × $grade');
        questions.add(PracticeQuestion(
          id: 'math_${grade}_$i',
          subject: Subject.math,
          grade: grade,
          question: '$expression = ?',
          options: makeNumberOptions(answer, i),
          answer: '$answer',
          explanation: '按运算顺序计算 $expression。',
        ));
      }
    }
    final cnWords = chineseWordsByGrade[grade]!;
    for (var i = 0; i < min(140, cnWords.length); i++) {
      final word = cnWords[i % cnWords.length];
      final target = word.substring(0, 1);
      final options = makeChineseWordOptions(cnWords, word, target, i);
      questions.add(PracticeQuestion(
        id: 'chinese_${grade}_$i',
        subject: Subject.chinese,
        grade: grade,
        question: '下面哪个词语含有“$target”字？',
        options: options,
        answer: word,
        explanation: '$word 来自小学语文生字组词资料。',
      ));
    }
    final enWords = englishWordsByGrade[grade]!;
    final entries = enWords.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i % entries.length];
      questions.add(PracticeQuestion(
        id: 'english_${grade}_$i',
        subject: Subject.english,
        grade: grade,
        question: '${entry.key} 的中文意思是？',
        options: makeMeaningOptions(entry.value, i),
        answer: entry.value,
        explanation: '${entry.key} 表示${entry.value}。',
      ));
    }
  }
  return questions;
}

void addFirstGradeMathQuestions(List<PracticeQuestion> questions) {
  var index = 1;

  void addQuestion(String question, int answer, String explanation) {
    questions.add(PracticeQuestion(
      id: 'math_1_${index++}',
      subject: Subject.math,
      grade: 1,
      question: question,
      options: makeNumberOptions(answer, index),
      answer: '$answer',
      explanation: explanation,
    ));
  }

  for (var a = 0; a <= 10; a++) {
    for (var b = 0; b <= 10; b++) {
      if (a + b <= 20) {
        addQuestion('$a + $b = ?', a + b, '把 $a 和 $b 合起来，得 ${a + b}。');
      }
    }
  }

  for (var a = 1; a <= 20; a++) {
    for (var b = 0; b <= min(10, a); b++) {
      addQuestion('$a - $b = ?', a - b, '从 $a 里面去掉 $b，剩下 ${a - b}。');
    }
  }

  for (var number = 10; number <= 20; number++) {
    final tens = number ~/ 10;
    final ones = number % 10;
    addQuestion('$tens 个十和 $ones 个一合起来是几？', number, '$tens 个十是 ${tens * 10}，再加 $ones 个一，是 $number。');
  }

  for (var start = 0; start <= 16; start += 2) {
    addQuestion('$start，${start + 1}，${start + 2}，__', start + 3, '按顺序每次多 1，下一项是 ${start + 3}。');
  }

  final storyProblems = [
    ('小明有 6 支铅笔，又买了 4 支，一共有几支？', 10, '6 + 4 = 10。'),
    ('树上有 12 只鸟，飞走 5 只，还剩几只？', 7, '12 - 5 = 7。'),
    ('妈妈买了 8 个苹果和 7 个梨，一共买了几个水果？', 15, '8 + 7 = 15。'),
    ('盒子里有 16 颗糖，吃了 6 颗，还剩几颗？', 10, '16 - 6 = 10。'),
    ('停车场有 9 辆车，又开来 3 辆，现在有几辆？', 12, '9 + 3 = 12。'),
    ('花园里有 14 朵花，摘走 4 朵，还剩几朵？', 10, '14 - 4 = 10。'),
  ];
  for (final item in storyProblems) {
    addQuestion(item.$1, item.$2, item.$3);
  }

  for (var a = 0; a <= 20; a += 2) {
    final b = (a + 3) % 21;
    final answer = a == b ? 0 : (a > b ? 1 : -1);
    final symbol = answer == 0 ? '=' : (answer > 0 ? '>' : '<');
    questions.add(PracticeQuestion(
      id: 'math_1_${index++}',
      subject: Subject.math,
      grade: 1,
      question: '$a ○ $b，○ 里应填什么？',
      options: const ['>', '<', '='],
      answer: symbol,
      explanation: '$a 和 $b 比较，应填 $symbol。',
    ));
  }
}

List<String> makeNumberOptions(int answer, int seed) {
  final values = <int>{answer, answer + 1, answer + 3, max(0, answer - 2)}.toList()..sort();
  return rotateOptions(values.map((value) => '$value').toList(), seed);
}

List<String> makeChineseWordOptions(List<String> words, String answer, String target, int seed) {
  final pool = words.where((item) => item != answer && !item.contains(target)).toList();
  final values = <String>{answer, ...pool.take(3)}.toList();
  return rotateOptions(values, seed);
}

List<String> makeMeaningOptions(String answer, int seed) {
  final pool = englishVocabulary.map((item) => item.meaning).where((item) => item != answer).toList();
  final values = <String>{answer, ...pool.where((item) => item != answer).take(3)}.toList();
  return rotateOptions(values.take(4).toList(), seed);
}

List<String> rotateOptions(List<String> values, int seed) {
  if (values.isEmpty) {
    return values;
  }
  final offset = seed % values.length;
  return [...values.skip(offset), ...values.take(offset)];
}

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
      const GamesPage(),
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
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports),
            label: '游戏',
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
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset('assets/images/cover.png', height: 210, fit: BoxFit.cover),
        ),
        const SizedBox(height: 18),
        Text('学宝', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('练习、听写、闯关和本机题库', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        FutureBuilder<HomeDashboardData>(
          future: loadHomeDashboardData(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? HomeDashboardData.empty;
            final latest = data.records.isEmpty ? null : data.records.first;
            return Column(
              children: [
                AppPanel(
                  icon: Icons.dashboard_customize_outlined,
                  title: '学习面板',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${data.rewards.title}  等级 ${data.rewards.level}'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: data.rewards.currentLevelPoints / 100),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.35,
                        children: [
                          DashboardTile(label: '积分', value: '${data.rewards.points}', icon: Icons.stars_outlined),
                          DashboardTile(label: '连续学习', value: '${data.rewards.streak} 天', icon: Icons.local_fire_department_outlined),
                          DashboardTile(label: '练习题库', value: '${data.totalQuestions} 题', icon: Icons.fact_check_outlined),
                          DashboardTile(label: '听写词库', value: '${data.totalDictation} 个', icon: Icons.hearing_outlined),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppPanel(
                  icon: Icons.insights_outlined,
                  title: '最近学习',
                  child: latest == null
                      ? const Text('还没有学习记录，先完成一次练习或听写。')
                      : Text(
                          '${latest.subject.label} ${latest.mode}：${latest.score} 分，'
                          '${latest.correct}/${latest.total} 正确，用时 ${formatDuration(latest.durationSeconds)}',
                        ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.92,
          children: Subject.values.map((subject) => SubjectCard(subject: subject)).toList(),
        ),
        const SizedBox(height: 12),
        const AppPanel(
          icon: Icons.security_outlined,
          title: '本地隐私',
          child: Text('练习记录保存在当前手机。TTS 朗读和 AI 小提示只会调用你在设置中配置的 API。'),
        ),
      ],
    );
  }
}

class HomeDashboardData {
  const HomeDashboardData({
    required this.rewards,
    required this.records,
    required this.customQuestions,
    required this.customDictation,
  });

  final RewardProfile rewards;
  final List<PracticeRecord> records;
  final List<PracticeQuestion> customQuestions;
  final List<DictationItem> customDictation;

  int get totalQuestions => questionBank.length + customQuestions.length;
  int get totalDictation => dictationBank.length + customDictation.length;

  static const empty = HomeDashboardData(
    rewards: RewardProfile.empty,
    records: [],
    customQuestions: [],
    customDictation: [],
  );
}

Future<HomeDashboardData> loadHomeDashboardData() async {
  final values = await Future.wait<Object>([
    LocalStore.loadRewards(),
    LocalStore.loadRecords(),
    LocalStore.loadCustomQuestions(),
    LocalStore.loadCustomDictation(),
  ]);
  return HomeDashboardData(
    rewards: values[0] as RewardProfile,
    records: values[1] as List<PracticeRecord>,
    customQuestions: values[2] as List<PracticeQuestion>,
    customDictation: values[3] as List<DictationItem>,
  );
}

class DashboardTile extends StatelessWidget {
  const DashboardTile({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
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
  int _practiceCount = 10;
  int _wordStudyCount = 20;
  late final Future<List<PracticeQuestion>> _customFuture = LocalStore.loadCustomQuestions();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle(icon: Icons.assignment_outlined, title: '科目练习', subtitle: '选择科目和年级后开始做题'),
        const SizedBox(height: 20),
        SubjectSelector(
          value: _subject,
          subjects: const [Subject.math, Subject.english],
          onChanged: (value) => setState(() => _subject = value),
        ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('已匹配 ${questions.length} 道题，其中自定义 $customCount 道。'),
                      const SizedBox(height: 12),
                      const Text('本次练习数量'),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 10, label: Text('10题')),
                            ButtonSegment(value: 20, label: Text('20题')),
                            ButtonSegment(value: 30, label: Text('30题')),
                            ButtonSegment(value: 50, label: Text('50题')),
                          ],
                          selected: {_practiceCount},
                          onSelectionChanged: (selection) => setState(() => _practiceCount = selection.first),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_subject == Subject.english) ...[
                  AppPanel(
                    icon: Icons.style_outlined,
                    title: '背单词',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('本年级共享词库 ${englishVocabulary.where((item) => item.grade == _grade).length} 个词，练习、听写和背单词共用。'),
                        const SizedBox(height: 12),
                        const Text('本次背词数量'),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 10, label: Text('10个')),
                              ButtonSegment(value: 20, label: Text('20个')),
                              ButtonSegment(value: 50, label: Text('50个')),
                              ButtonSegment(value: 100, label: Text('100个')),
                            ],
                            selected: {_wordStudyCount},
                            onSelectionChanged: (selection) => setState(() => _wordStudyCount = selection.first),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => WordStudyPage(grade: _grade, count: _wordStudyCount)),
                            );
                          },
                          icon: const Icon(Icons.play_lesson_outlined),
                          label: const Text('开始背单词'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                const AppPanel(
                  icon: Icons.data_object_outlined,
                  title: '题库导入',
                  child: Text('请到设置页使用标准 JSON 导入数学题、英语题、英语单词或语文听写词。'),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: questions.isEmpty
                      ? null
                      : () {
                          final picked = [...questions]..shuffle(Random());
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuizPage(
                                subject: _subject,
                                grade: _grade,
                                questions: picked.take(_practiceCount).toList(),
                              ),
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

}

class WordStudyPage extends StatefulWidget {
  const WordStudyPage({required this.grade, required this.count, super.key});

  final int grade;
  final int count;

  @override
  State<WordStudyPage> createState() => _WordStudyPageState();
}

class _WordStudyPageState extends State<WordStudyPage> {
  final _tts = AppTtsService();
  late Future<List<WordStudyItem>> _future;
  List<WordStudyItem> _words = [];
  int _index = 0;
  bool _showMeaning = true;

  @override
  void initState() {
    super.initState();
    _future = _loadWords();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.grade} 年级背单词')),
      body: FutureBuilder<List<WordStudyItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_words.isEmpty) {
            return const Center(child: Text('当前年级没有可背单词。'));
          }
          final word = _words[_index];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              LinearProgressIndicator(value: (_index + 1) / _words.length),
              const SizedBox(height: 16),
              Text('第 ${_index + 1} 个 / 共 ${_words.length} 个', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 18),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word.word, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Text('${word.partOfSpeech}  ${word.category}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 22),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _showMeaning
                            ? Text(
                                word.meaning,
                                key: ValueKey(word.word),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                              )
                            : Text(
                                '点击显示中文',
                                key: ValueKey('${word.word}_hidden'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _speakCurrent,
                    icon: const Icon(Icons.volume_up_outlined),
                    label: const Text('播放'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _showMeaning = !_showMeaning),
                    icon: Icon(_showMeaning ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    label: Text(_showMeaning ? '隐藏中文' : '显示中文'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _words.isEmpty || _index == 0 ? null : _previous,
                child: const Text('上一个'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _words.isEmpty || _index == _words.length - 1 ? null : _next,
                child: const Text('下一个'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<WordStudyItem>> _loadWords() async {
    final custom = await LocalStore.loadCustomDictation();
    final byWord = <String, WordStudyItem>{
      for (final item in englishVocabulary.where((item) => item.grade == widget.grade))
        item.word: WordStudyItem(
          word: item.word,
          meaning: item.meaning,
          partOfSpeech: item.partOfSpeech,
          category: item.category,
        ),
    };
    for (final item in custom.where((item) => item.subject == Subject.english && item.grade == widget.grade)) {
      if (item.text.trim().isEmpty) {
        continue;
      }
      byWord[item.text] = WordStudyItem(
        word: item.text,
        meaning: item.hint.isEmpty ? '导入单词' : item.hint,
        partOfSpeech: 'import',
        category: 'JSON 导入',
      );
    }
    final values = byWord.values.toList()..shuffle(Random());
    final selected = values.take(widget.count).toList();
    if (mounted) {
      setState(() => _words = selected);
      if (selected.isNotEmpty) {
        unawaited(_speakCurrent());
      }
    }
    return selected;
  }

  Future<void> _speakCurrent() async {
    if (_words.isEmpty) {
      return;
    }
    try {
      await _tts.speak(text: _words[_index].word, slow: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  void _previous() {
    if (_index == 0) {
      return;
    }
    setState(() {
      _index--;
      _showMeaning = true;
    });
    _speakCurrent();
  }

  void _next() {
    if (_index >= _words.length - 1) {
      return;
    }
    setState(() {
      _index++;
      _showMeaning = true;
    });
    _speakCurrent();
  }
}

class DictationEntryPage extends StatefulWidget {
  const DictationEntryPage({super.key});

  @override
  State<DictationEntryPage> createState() => _DictationEntryPageState();
}

class GamesPage extends StatefulWidget {
  const GamesPage({super.key});

  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  Subject _subject = Subject.math;
  int _grade = 1;
  late final Future<List<PracticeQuestion>> _customFuture = LocalStore.loadCustomQuestions();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle(icon: Icons.sports_esports_outlined, title: '学习游戏', subtitle: '限时闯关、生命值和连击得分'),
        const SizedBox(height: 20),
        SubjectSelector(
          value: _subject,
          subjects: const [Subject.math, Subject.english],
          onChanged: (value) => setState(() => _subject = value),
        ),
        const SizedBox(height: 18),
        GradeSelector(value: _grade, onChanged: (value) => setState(() => _grade = value)),
        const SizedBox(height: 18),
        FutureBuilder<List<PracticeQuestion>>(
          future: _customFuture,
          builder: (context, snapshot) {
            final custom = snapshot.data ?? [];
            final questions = [
              ...custom,
              ...questionBank,
            ].where((item) => item.subject == _subject && item.grade == _grade).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPanel(
                  icon: Icons.bolt_outlined,
                  title: '星星闯关',
                  child: Text('60 秒，3 颗心，连对会加分。本年级可抽取 ${questions.length} 道题。'),
                ),
                const SizedBox(height: 12),
                const AppPanel(
                  icon: Icons.military_tech_outlined,
                  title: '规则',
                  child: Text('答对加分，连续答对分数更高；答错扣一颗心，心用完立即结束。'),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: questions.isEmpty
                      ? null
                      : () {
                          final picked = [...questions]..shuffle(Random());
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GameSessionPage(
                                subject: _subject,
                                grade: _grade,
                                questions: picked.take(20).toList(),
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始游戏'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class GameSessionPage extends StatefulWidget {
  const GameSessionPage({
    required this.subject,
    required this.grade,
    required this.questions,
    super.key,
  });

  final Subject subject;
  final int grade;
  final List<PracticeQuestion> questions;

  @override
  State<GameSessionPage> createState() => _GameSessionPageState();
}

class _GameSessionPageState extends State<GameSessionPage> {
  final _answerController = TextEditingController();
  final _results = <ResultItem>[];
  final _startAt = DateTime.now();
  Timer? _timer;
  int _remaining = 60;
  int _lives = 3;
  int _score = 0;
  int _combo = 0;
  int _index = 0;
  bool _locked = false;
  bool _finished = false;
  String _feedback = '准备答题';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finished) {
        return;
      }
      if (_remaining <= 1) {
        setState(() => _remaining = 0);
        _finish();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_index];
    return Scaffold(
      appBar: AppBar(title: Text('${widget.subject.label}游戏')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: _GameStat(icon: Icons.timer_outlined, label: '时间', value: '${_remaining}s')),
              const SizedBox(width: 8),
              Expanded(child: _GameStat(icon: Icons.favorite_outline, label: '生命', value: '$_lives')),
              const SizedBox(width: 8),
              Expanded(child: _GameStat(icon: Icons.stars_outlined, label: '得分', value: '$_score')),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: (_index + 1) / widget.questions.length),
          const SizedBox(height: 16),
          Text('第 ${_index + 1} 题 / 共 ${widget.questions.length} 题  连击 $_combo', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 16),
          Text(question.question, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          if (question.options.isEmpty) ...[
            TextField(
              controller: _answerController,
              enabled: !_locked,
              decoration: const InputDecoration(labelText: '输入答案', border: OutlineInputBorder()),
              onSubmitted: (_) => _submitInput(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _locked ? null : _submitInput,
              icon: const Icon(Icons.check_outlined),
              label: const Text('提交'),
            ),
          ] else
            ...question.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FilledButton.tonal(
                  onPressed: _locked ? null : () => _answer(option),
                  child: Text(option),
                ),
              ),
            ),
          const SizedBox(height: 12),
          AppPanel(
            icon: _feedback.startsWith('正确') ? Icons.check_circle_outline : Icons.info_outline,
            title: '状态',
            child: Text(_feedback),
          ),
        ],
      ),
    );
  }

  void _submitInput() {
    final value = _answerController.text.trim();
    if (value.isEmpty) {
      return;
    }
    _answer(value);
  }

  void _answer(String answer) {
    if (_locked || _finished) {
      return;
    }
    final question = widget.questions[_index];
    final correct = question.options.isEmpty
        ? normalizeAnswer(answer, question.subject) == normalizeAnswer(question.answer, question.subject)
        : answer == question.answer;
    setState(() {
      _locked = true;
      if (correct) {
        _score += 10 + _combo * 2;
        _combo++;
        _feedback = '正确，连击 $_combo';
      } else {
        _lives--;
        _combo = 0;
        _feedback = '错误，剩余 $_lives 颗心';
      }
      _results.add(
        ResultItem(
          sourceId: question.id,
          subject: question.subject,
          grade: question.grade,
          mode: '游戏',
          question: question.question,
          correctAnswer: question.answer,
          userAnswer: answer,
          explanation: question.explanation,
          isCorrect: correct,
        ),
      );
    });

    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted || _finished) {
        return;
      }
      if (_lives <= 0 || _index == widget.questions.length - 1) {
        _finish();
        return;
      }
      setState(() {
        _index++;
        _locked = false;
        _answerController.clear();
      });
    });
  }

  Future<void> _finish() async {
    if (_finished) {
      return;
    }
    _finished = true;
    _timer?.cancel();
    if (_results.isEmpty) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }
    await saveResultAndOpenPage(context, _results, _startAt);
  }
}

class _GameStat extends StatelessWidget {
  const _GameStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _DictationEntryPageState extends State<DictationEntryPage> {
  Subject _subject = Subject.chinese;
  int _grade = 1;
  int _autoNextSeconds = 0;
  int _itemCount = 10;
  late final Future<List<DictationItem>> _customFuture = LocalStore.loadCustomDictation();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle(icon: Icons.record_voice_over_outlined, title: '听写训练', subtitle: '使用 TTS API 朗读'),
        const SizedBox(height: 20),
        SubjectSelector(
          value: _subject,
          subjects: const [Subject.chinese, Subject.english],
          onChanged: (value) => setState(() => _subject = value),
        ),
        const SizedBox(height: 18),
        GradeSelector(value: _grade, onChanged: (value) => setState(() => _grade = value)),
        const SizedBox(height: 18),
        AppPanel(
          icon: Icons.timer_outlined,
          title: '听写设置',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('数量'),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 5, label: Text('5个')),
                  ButtonSegment(value: 10, label: Text('10个')),
                  ButtonSegment(value: 15, label: Text('15个')),
                  ButtonSegment(value: 20, label: Text('20个')),
                ],
                selected: {_itemCount},
                onSelectionChanged: (selection) => setState(() => _itemCount = selection.first),
              ),
              const SizedBox(height: 14),
              const Text('自动下一个'),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('手动')),
                  ButtonSegment(value: 8, label: Text('8秒')),
                  ButtonSegment(value: 12, label: Text('12秒')),
                  ButtonSegment(value: 20, label: Text('20秒')),
                ],
                selected: {_autoNextSeconds},
                onSelectionChanged: (selection) => setState(() => _autoNextSeconds = selection.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<DictationItem>>(
          future: _customFuture,
          builder: (context, snapshot) {
            final custom = snapshot.data ?? [];
            final allItems = _itemsForCurrentSelection(custom);
            final selectedCount = min(_itemCount, allItems.length);
            final customCount = allItems.where((item) => item.id.startsWith('custom_')).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPanel(
                  icon: Icons.hearing_outlined,
                  title: '听写说明',
                  child: Text(
                    '本次随机听写 $selectedCount 个，可选总量 ${allItems.length} 个，其中自定义 $customCount 个。'
                    '${_subject == Subject.chinese ? '语文内置词来自生字组词资料。' : '英文听写和背单词共用同一词库。'}'
                    '孩子写在纸上，结束后家长勾选对错。',
                  ),
                ),
                const SizedBox(height: 18),
                const AppPanel(
                  icon: Icons.data_object_outlined,
                  title: '词库导入',
                  child: Text('请到设置页使用标准 JSON 导入语文词语或英语单词。导入后重新进入听写页即可看到新增内容。'),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: allItems.isEmpty
                      ? null
                      : () {
                          final picked = [...allItems]..shuffle(Random());
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DictationSessionPage(
                                subject: _subject,
                                grade: _grade,
                                items: picked.take(_itemCount).toList(),
                                autoNextSeconds: _autoNextSeconds,
                              ),
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

int parseImportGrade(Object? value) {
  final parsed = value is int ? value : int.tryParse('${value ?? ''}');
  return (parsed ?? 1).clamp(1, 6).toInt();
}

bool shouldGenerateOptions(Map<String, dynamic> item, Subject subject) {
  if (item['input'] == true || item['inputAnswer'] == true) {
    return false;
  }
  if (item['choice'] == true || item['autoOptions'] == true) {
    return true;
  }
  final type = '${item['type'] ?? item['mode'] ?? ''}'.trim().toLowerCase();
  if (type.contains('word_problem') || type.contains('application') || type.contains('应用')) {
    return false;
  }
  if (type.contains('calculation') || type.contains('choice') || type.contains('计算') || type.contains('选择')) {
    return true;
  }
  return subject == Subject.english;
}

List<String> autoOptionsForQuestion({
  required Subject subject,
  required String answer,
  required int seed,
}) {
  final trimmed = answer.trim();
  if (trimmed.isEmpty) {
    return const [];
  }

  final numeric = num.tryParse(trimmed);
  if (numeric != null) {
    final values = <String>{trimmed};
    final offsets = [1, -1, 2, -2, 3, 5, -3, 10, -5, -10];
    for (final offset in offsets) {
      final next = numeric + offset;
      if (next < 0) {
        continue;
      }
      values.add(next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(1));
      if (values.length >= 4) {
        break;
      }
    }
    return rotateOptions(values.take(4).toList(), seed);
  }

  final pool = subject == Subject.english
      ? englishVocabulary.map((word) => word.meaning)
      : <String>[
          '较大',
          '较小',
          '相等',
          '不能确定',
          '加法',
          '减法',
          '乘法',
          '除法',
        ];
  final options = <String>{trimmed};
  for (final value in pool) {
    if (value.trim().isNotEmpty && value != trimmed) {
      options.add(value);
    }
    if (options.length >= 4) {
      break;
    }
  }
  while (options.length < 4) {
    options.add('选项 ${options.length + 1}');
  }
  return rotateOptions(options.take(4).toList(), seed);
}

class JsonImportBundle {
  const JsonImportBundle({
    required this.questions,
    required this.dictationItems,
  });

  final List<PracticeQuestion> questions;
  final List<DictationItem> dictationItems;

  int get total => questions.length + dictationItems.length;
}

JsonImportBundle parseStandardImportJson(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('JSON 根节点必须是对象。');
  }

  final now = DateTime.now().millisecondsSinceEpoch;
  final questions = <PracticeQuestion>[];
  final dictationItems = <DictationItem>[];

  final questionValues = decoded['questions'];
  if (questionValues is List) {
    for (final value in questionValues) {
      if (value is! Map) {
        continue;
      }
      final item = Map<String, dynamic>.from(value);
      final subject = subjectFromImportValue(item['subject'] ?? 'math');
      if (subject == Subject.chinese) {
        continue;
      }
      final grade = parseImportGrade(item['grade']);
      final question = '${item['question'] ?? ''}'.trim();
      final answer = '${item['answer'] ?? ''}'.trim();
      if (question.isEmpty || answer.isEmpty) {
        continue;
      }
      var options = item['options'] is List
          ? (item['options'] as List).map((option) => '$option'.trim()).where((option) => option.isNotEmpty).toList()
          : <String>[];
      if (options.isEmpty && shouldGenerateOptions(item, subject)) {
        options = autoOptionsForQuestion(
          subject: subject,
          answer: answer,
          seed: questions.length,
        );
      }
      questions.add(
        PracticeQuestion(
          id: 'custom_question_${now}_${questions.length}',
          subject: subject,
          grade: grade,
          question: question,
          options: options,
          answer: options.isEmpty ? answer : resolveOptionAnswer(answer, options),
          explanation: '${item['explanation'] ?? '导入题目。'}',
        ),
      );
    }
  }

  final dictationValues = decoded['dictation'];
  if (dictationValues is List) {
    for (final value in dictationValues) {
      if (value is! Map) {
        continue;
      }
      final item = Map<String, dynamic>.from(value);
      final subject = subjectFromImportValue(item['subject'] ?? 'chinese');
      if (subject == Subject.math) {
        continue;
      }
      final grade = parseImportGrade(item['grade']);
      final text = '${item['text'] ?? item['word'] ?? ''}'.trim();
      if (text.isEmpty) {
        continue;
      }
      dictationItems.add(
        DictationItem(
          id: 'custom_${now}_${dictationItems.length}',
          subject: subject,
          grade: grade,
          text: text,
          hint: '${item['hint'] ?? item['meaning'] ?? ''}'.trim(),
          sentence: '${item['sentence'] ?? 'JSON 导入。'}',
        ),
      );
    }
  }

  final wordValues = decoded['words'];
  if (wordValues is List) {
    final importedWords = <({String word, String meaning, int grade})>[];
    for (final value in wordValues) {
      if (value is! Map) {
        continue;
      }
      final item = Map<String, dynamic>.from(value);
      final grade = parseImportGrade(item['grade']);
      final word = '${item['word'] ?? item['text'] ?? ''}'.trim();
      final meaning = '${item['meaning'] ?? item['hint'] ?? ''}'.trim();
      if (word.isEmpty) {
        continue;
      }
      importedWords.add((word: word, meaning: meaning, grade: grade));
      dictationItems.add(
        DictationItem(
          id: 'custom_${now}_${dictationItems.length}',
          subject: Subject.english,
          grade: grade,
          text: word,
          hint: meaning,
          sentence: 'JSON 导入英语单词。',
        ),
      );
    }
    for (var i = 0; i < importedWords.length; i++) {
      final item = importedWords[i];
      if (item.meaning.isEmpty) {
        continue;
      }
      final importedMeanings = importedWords.map((word) => word.meaning).where((meaning) => meaning.isNotEmpty && meaning != item.meaning);
      final options = <String>{item.meaning, ...importedMeanings, ...englishVocabulary.map((word) => word.meaning)}.take(4).toList();
      questions.add(
        PracticeQuestion(
          id: 'custom_question_${now}_${questions.length}',
          subject: Subject.english,
          grade: item.grade,
          question: '${item.word} 的中文意思是？',
          options: rotateOptions(options, i),
          answer: item.meaning,
          explanation: '${item.word} 表示${item.meaning}。',
        ),
      );
    }
  }

  return JsonImportBundle(questions: questions, dictationItems: dictationItems);
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
  bool _hintLoading = false;

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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _hintLoading ? null : () => _showAiHint(question),
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(_hintLoading ? '提示生成中' : 'AI 小提示'),
            ),
          ),
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
            RadioGroup<String>(
              groupValue: _answers[question.id],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _answers[question.id] = value);
                }
              },
              child: Column(
                children: question.options
                    .map(
                      (option) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RadioListTile<String>(
                          value: option,
                          title: Text(option),
                          selected: _answers[question.id] == option,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          tileColor: Colors.white,
                        ),
                      ),
                    )
                    .toList(),
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

  Future<void> _showAiHint(PracticeQuestion question) async {
    setState(() => _hintLoading = true);
    try {
      final settings = await LocalStore.loadAiHintSettings();
      final used = await LocalStore.loadTodayAiHintCount();
      if (used >= settings.dailyLimit) {
        throw FormatException('今天 AI 小提示已用完：$used / ${settings.dailyLimit}');
      }
      final config = await LocalStore.loadAiConfig();
      final hint = await AiHintService.createHint(config: config, question: question);
      await LocalStore.useAiHint();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI 小提示'),
          content: Text(hint),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('知道了')),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _hintLoading = false);
      }
    }
  }
}

class DictationSessionPage extends StatefulWidget {
  const DictationSessionPage({
    required this.subject,
    required this.grade,
    required this.items,
    required this.autoNextSeconds,
    super.key,
  });

  final Subject subject;
  final int grade;
  final List<DictationItem> items;
  final int autoNextSeconds;

  @override
  State<DictationSessionPage> createState() => _DictationSessionPageState();
}

class _DictationSessionPageState extends State<DictationSessionPage> {
  final _tts = AppTtsService();
  final _startAt = DateTime.now();
  Timer? _autoTimer;
  int _index = 0;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _tts.dispose();
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
          if (widget.subject == Subject.english) ...[
            AppPanel(
              icon: Icons.lightbulb_outline,
              title: '英文提示',
              child: Text(item.hint),
            ),
            const SizedBox(height: 18),
          ],
          AppPanel(
            icon: Icons.edit_outlined,
            title: '纸上听写',
            child: Text(
              widget.autoNextSeconds > 0
                  ? '孩子写在纸上。${widget.autoNextSeconds} 秒后自动进入下一个，也可以手动点击。'
                  : '孩子写在纸上，写完后点击下一个。',
            ),
          ),
          const SizedBox(height: 12),
          Text('当前只朗读词语，不在手机上输入答案。', style: Theme.of(context).textTheme.bodySmall),
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
    _autoTimer?.cancel();
    final item = widget.items[_index];
    try {
      await _tts.speak(text: item.text, slow: _slow);
      _scheduleAutoNext();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  void _scheduleAutoNext() {
    if (widget.autoNextSeconds <= 0) {
      return;
    }
    _autoTimer = Timer(Duration(seconds: widget.autoNextSeconds), () {
      if (!mounted) {
        return;
      }
      if (_index == widget.items.length - 1) {
        _submit();
      } else {
        _next();
      }
    });
  }

  void _previous() {
    _autoTimer?.cancel();
    setState(() {
      _index--;
    });
    _speakCurrent();
  }

  void _next() {
    _autoTimer?.cancel();
    setState(() {
      _index++;
    });
    _speakCurrent();
  }

  Future<void> _submit() async {
    await _tts.stop();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DictationReviewPage(items: widget.items, startedAt: _startAt),
      ),
    );
  }
}

class DictationReviewPage extends StatefulWidget {
  const DictationReviewPage({
    required this.items,
    required this.startedAt,
    super.key,
  });

  final List<DictationItem> items;
  final DateTime startedAt;

  @override
  State<DictationReviewPage> createState() => _DictationReviewPageState();
}

class _DictationReviewPageState extends State<DictationReviewPage> {
  late final Map<String, bool> _correct = {for (final item in widget.items) item.id: true};

  @override
  Widget build(BuildContext context) {
    final correctCount = _correct.values.where((value) => value).length;
    return Scaffold(
      appBar: AppBar(title: const Text('家长批改')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppPanel(
            icon: Icons.checklist_outlined,
            title: '本次听写词语',
            child: Text('请根据孩子纸上的答案勾选对错。正确 $correctCount / ${widget.items.length}'),
          ),
          const SizedBox(height: 12),
          ...widget.items.map(
            (item) => Card(
              elevation: 0,
              child: SwitchListTile(
                value: _correct[item.id] ?? true,
                onChanged: (value) => setState(() => _correct[item.id] = value),
                title: Text(item.text),
                subtitle: item.subject == Subject.english ? Text(item.hint) : null,
                secondary: Icon((_correct[item.id] ?? true) ? Icons.check_circle_outline : Icons.cancel_outlined),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: FilledButton.icon(
          onPressed: _finish,
          icon: const Icon(Icons.done_all),
          label: const Text('完成批改'),
        ),
      ),
    );
  }

  Future<void> _finish() async {
    final results = widget.items.map((item) {
      final isCorrect = _correct[item.id] ?? true;
      return ResultItem(
        sourceId: item.id,
        subject: item.subject,
        grade: item.grade,
        mode: '听写',
        question: '听写：${item.text}',
        correctAnswer: item.text,
        userAnswer: isCorrect ? '家长标记正确' : '家长标记错误',
        explanation: item.subject == Subject.english ? item.hint : '纸上听写。',
        isCorrect: isCorrect,
      );
    }).toList();
    await saveResultAndOpenPage(context, results, widget.startedAt);
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
  final rewards = await LocalStore.addReward(score: score, total: results.length);
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
      builder: (_) => ResultPage(
        results: results,
        score: score,
        correct: correct,
        durationSeconds: duration,
        rewards: rewards,
      ),
    ),
  );
}

class ResultPage extends StatelessWidget {
  const ResultPage({
    required this.results,
    required this.score,
    required this.correct,
    required this.durationSeconds,
    required this.rewards,
    super.key,
  });

  final List<ResultItem> results;
  final int score;
  final int correct;
  final int durationSeconds;
  final RewardProfile rewards;

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
                  const SizedBox(height: 8),
                  Text('获得积分，当前等级 ${rewards.level}，总积分 ${rewards.points}'),
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
  final _tts = AppTtsService();
  late Future<AiConfig> _aiFuture = LocalStore.loadAiConfig();
  late Future<TtsApiConfig> _ttsFuture = LocalStore.loadTtsApiConfig();
  late Future<AiHintSettings> _hintFuture = LocalStore.loadAiHintSettings();

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle(icon: Icons.settings_outlined, title: '设置', subtitle: 'TTS API 和本机数据'),
        const SizedBox(height: 16),
        AppPanel(
          icon: Icons.data_object_outlined,
          title: 'JSON 题库导入',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('用标准 JSON 增量导入数学题、英语题、英语单词、语文和英语听写词。'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _openJsonImport,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('导入 JSON'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await LocalStore.clearCustomQuestions();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已清空自定义题库。')),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('清空题库'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await LocalStore.clearCustomDictation();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已清空自定义词库。')),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('清空词库'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<TtsApiConfig>(
          future: _ttsFuture,
          builder: (context, snapshot) {
            final config = snapshot.data ?? TtsApiConfig.empty;
            return AppPanel(
              icon: Icons.graphic_eq_outlined,
              title: 'TTS API',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(config.isReady ? '已开启：${config.model} / ${config.voice}' : '未开启。听写和背单词朗读需要 OpenAI 格式 /audio/speech API。'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _openTtsApiSettings,
                        icon: const Icon(Icons.tune_outlined),
                        label: const Text('配置 TTS API'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _speak('你好，欢迎使用学宝。'),
                        icon: const Icon(Icons.record_voice_over_outlined),
                        label: const Text('测试朗读'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<AiConfig>(
          future: _aiFuture,
          builder: (context, snapshot) {
            final config = snapshot.data ?? AiConfig.empty;
            return AppPanel(
              icon: Icons.auto_awesome_outlined,
              title: 'AI API 渠道',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(config.isReady ? '已开启：${config.model}' : '未开启。可用于练习页 AI 小提示。'),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _openAiSettings,
                    icon: const Icon(Icons.tune_outlined),
                    label: const Text('配置 AI'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<AiHintSettings>(
          future: _hintFuture,
          builder: (context, snapshot) {
            final settings = snapshot.data ?? AiHintSettings.defaults;
            return AppPanel(
              icon: Icons.lightbulb_outline,
              title: 'AI 小提示次数',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('每天最多使用 ${settings.dailyLimit} 次。修改需要管理密码。'),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _openHintSettings,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('设置次数'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const AppPanel(
          icon: Icons.lock_outline,
          title: '隐私',
          child: Text('学宝不需要登录。错题、听写和成绩记录保存在本机；TTS 和 AI 功能会调用你配置的 API。'),
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

  Future<void> _speak(String text) async {
    try {
      await _tts.speak(text: text, slow: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _openAiSettings() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiSettingsPage()));
    if (mounted) {
      setState(() => _aiFuture = LocalStore.loadAiConfig());
    }
  }

  Future<void> _openJsonImport() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JsonImportPage()));
  }

  Future<void> _openHintSettings() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiHintSettingsPage()));
    if (mounted) {
      setState(() => _hintFuture = LocalStore.loadAiHintSettings());
    }
  }

  Future<void> _openTtsApiSettings() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TtsApiSettingsPage()));
    if (mounted) {
      setState(() => _ttsFuture = LocalStore.loadTtsApiConfig());
    }
  }
}

class JsonImportPage extends StatefulWidget {
  const JsonImportPage({super.key});

  @override
  State<JsonImportPage> createState() => _JsonImportPageState();
}

class _JsonImportPageState extends State<JsonImportPage> {
  final _controller = TextEditingController();
  JsonImportBundle? _bundle;
  String? _message;

  @override
  void initState() {
    super.initState();
    _controller.text = standardJsonExample;
    _parse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    return Scaffold(
      appBar: AppBar(title: const Text('导入 JSON')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageTitle(icon: Icons.data_object_outlined, title: '标准 JSON 导入', subtitle: '粘贴 JSON，预览无误后保存到本机题库'),
          const SizedBox(height: 16),
          AppPanel(
            icon: Icons.rule_outlined,
            title: '可导入内容',
            child: const Text('questions：数学/英语练习题；dictation：语文/英语听写词；words：英语单词，会自动加入背单词、听写和英语练习。'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 14,
            maxLines: 24,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'JSON 内容',
            ),
            onChanged: (_) => _parse(),
          ),
          const SizedBox(height: 12),
          AppPanel(
            icon: Icons.fact_check_outlined,
            title: '导入预览',
            child: Text(
              bundle == null
                  ? (_message ?? 'JSON 无法解析。')
                  : '练习题 ${bundle.questions.length} 道，听写/单词 ${bundle.dictationItems.length} 个。',
              style: _message == null ? null : TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: bundle == null || bundle.total == 0 ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('保存到本机'),
          ),
        ],
      ),
    );
  }

  void _parse() {
    try {
      final parsed = parseStandardImportJson(_controller.text);
      setState(() {
        _bundle = parsed;
        _message = null;
      });
    } catch (error) {
      setState(() {
        _bundle = null;
        _message = '$error';
      });
    }
  }

  Future<void> _save() async {
    final bundle = _bundle;
    if (bundle == null) {
      return;
    }
    await LocalStore.addCustomQuestions(bundle.questions);
    await LocalStore.addCustomDictation(bundle.dictationItems);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已导入 ${bundle.questions.length} 道题、${bundle.dictationItems.length} 个词。')),
    );
    Navigator.of(context).pop();
  }
}

const standardJsonExample = '''
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
''';

class AiHintSettingsPage extends StatefulWidget {
  const AiHintSettingsPage({super.key});

  @override
  State<AiHintSettingsPage> createState() => _AiHintSettingsPageState();
}

class _AiHintSettingsPageState extends State<AiHintSettingsPage> {
  final _password = TextEditingController();
  final _dailyLimit = TextEditingController(text: '3');

  @override
  void initState() {
    super.initState();
    LocalStore.loadAiHintSettings().then((settings) {
      if (!mounted) {
        return;
      }
      _dailyLimit.text = settings.dailyLimit.toString();
    });
  }

  @override
  void dispose() {
    _password.dispose();
    _dailyLimit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 小提示次数')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageTitle(icon: Icons.lightbulb_outline, title: '每日次数设置', subtitle: '需要管理密码才能修改'),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: '管理密码', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dailyLimit,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '每天可用次数', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_password.text.trim() != '200772') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('密码不正确。')));
      return;
    }
    final limit = int.tryParse(_dailyLimit.text.trim());
    if (limit == null || limit < 0 || limit > 99) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('次数需要是 0 到 99 的数字。')));
      return;
    }
    await LocalStore.saveAiHintSettings(AiHintSettings(dailyLimit: limit));
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key});

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  final _baseUrl = TextEditingController();
  final _apiKey = TextEditingController();
  final _model = TextEditingController();
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    LocalStore.loadAiConfig().then((config) {
      if (!mounted) {
        return;
      }
      setState(() {
        _enabled = config.enabled;
        _baseUrl.text = config.baseUrl;
        _apiKey.text = config.apiKey;
        _model.text = config.model;
      });
    });
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI API 设置')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
            title: const Text('启用 AI 小提示'),
            subtitle: const Text('开启后，练习页可调用你配置的 AI API 生成解题提示。'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _baseUrl, decoration: const InputDecoration(labelText: 'Base URL', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _model, decoration: const InputDecoration(labelText: '模型', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _apiKey, obscureText: true, decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('保存')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    await LocalStore.saveAiConfig(AiConfig(enabled: _enabled, baseUrl: _baseUrl.text.trim(), apiKey: _apiKey.text.trim(), model: _model.text.trim()));
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class TtsApiSettingsPage extends StatefulWidget {
  const TtsApiSettingsPage({super.key});

  @override
  State<TtsApiSettingsPage> createState() => _TtsApiSettingsPageState();
}

class _TtsApiSettingsPageState extends State<TtsApiSettingsPage> {
  final _baseUrl = TextEditingController();
  final _apiKey = TextEditingController();
  final _model = TextEditingController();
  final _voice = TextEditingController();
  final _tester = AppTtsService();
  bool _enabled = false;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    LocalStore.loadTtsApiConfig().then((config) {
      if (!mounted) {
        return;
      }
      setState(() {
        _enabled = config.enabled;
        _baseUrl.text = config.baseUrl;
        _apiKey.text = config.apiKey;
        _model.text = config.model;
        _voice.text = config.voice;
      });
    });
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    _voice.dispose();
    _tester.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TTS API 设置')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
            title: const Text('启用 TTS API'),
            subtitle: const Text('听写和背单词会直接调用这里配置的 OpenAI 格式 /audio/speech。'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _baseUrl, decoration: const InputDecoration(labelText: 'Base URL', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _model, decoration: const InputDecoration(labelText: 'TTS 模型', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
            controller: _voice,
            decoration: const InputDecoration(
              labelText: 'Voice',
              helperText: 'SiliconFlow 可填 anna，发送时会自动转为 模型名:anna。',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _apiKey, obscureText: true, decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder())),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('保存')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _testing ? null : _testApi,
            icon: const Icon(Icons.record_voice_over_outlined),
            label: Text(_testing ? '测试中' : '测试 TTS API'),
          ),
        ],
      ),
    );
  }

  TtsApiConfig _currentConfig() {
    return TtsApiConfig(
      enabled: _enabled,
      baseUrl: _baseUrl.text.trim(),
      apiKey: _apiKey.text.trim(),
      model: _model.text.trim(),
      voice: _voice.text.trim(),
    );
  }

  Future<void> _save() async {
    await LocalStore.saveTtsApiConfig(_currentConfig());
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _testApi() async {
    setState(() => _testing = true);
    try {
      await _tester.speakWithApiOnly(config: _currentConfig(), text: '你好，欢迎使用学宝。', slow: false);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 1, label: Text('一')),
          ButtonSegment(value: 2, label: Text('二')),
          ButtonSegment(value: 3, label: Text('三')),
          ButtonSegment(value: 4, label: Text('四')),
          ButtonSegment(value: 5, label: Text('五')),
          ButtonSegment(value: 6, label: Text('六')),
        ],
        selected: {value},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
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
