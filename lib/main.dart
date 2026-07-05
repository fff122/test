import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
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

class AiImportService {
  static Future<String> analyzeImage({
    required AiConfig config,
    required XFile image,
    required String instruction,
  }) async {
    if (!config.isReady) {
      throw const FormatException('请先在设置中开启并填写 AI API 渠道。');
    }

    final bytes = await File(image.path).readAsBytes();
    final imageBase64 = base64Encode(bytes);
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
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': instruction},
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'},
                  },
                ],
              },
            ],
            'temperature': 0.1,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException('AI 接口返回 ${response.statusCode}：${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const FormatException('AI 接口没有返回可用内容。');
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content'];
    if (content is String) {
      return stripCodeFence(content).trim();
    }
    if (content is List) {
      return content
          .map((item) => item is Map && item['text'] is String ? item['text'] as String : '')
          .where((text) => text.trim().isNotEmpty)
          .join('\n')
          .trim();
    }
    throw const FormatException('AI 返回格式无法解析。');
  }
}

class AppTtsService {
  AppTtsService();

  final _systemTts = FlutterTts();
  final _apiPlayer = AudioPlayer();
  bool _disposed = false;

  Future<void> speak({
    required String text,
    required String language,
    required bool slow,
  }) async {
    if (_disposed) {
      return;
    }

    await stop();
    Object? systemError;
    try {
      await _speakWithSystemTts(text: text, language: language, slow: slow);
      return;
    } catch (error) {
      systemError = error;
    }

    final config = await LocalStore.loadTtsApiConfig();
    if (!config.isReady) {
      throw FormatException(
        '手机自带 TTS 无法朗读。请到设置里启用并填写 OpenAI 格式 TTS API。'
        '\n手机自带 TTS 错误：$systemError',
      );
    }
    await _speakWithApi(config: config, text: text, slow: slow);
  }

  Future<void> stop() async {
    await _systemTts.stop();
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
    unawaited(_systemTts.stop());
    unawaited(_apiPlayer.dispose());
  }

  Future<void> _speakWithSystemTts({
    required String text,
    required String language,
    required bool slow,
  }) async {
    await _systemTts.awaitSpeakCompletion(true);
    await _systemTts.setLanguage(language);
    await _systemTts.setSpeechRate(slow ? 0.35 : 0.48);
    await _systemTts.setPitch(1);
    final result = await _systemTts.speak(text);
    if (result is int && result == 0) {
      throw const FormatException('手机自带 TTS 返回失败。');
    }
  }

  Future<void> _speakWithApi({
    required TtsApiConfig config,
    required String text,
    required bool slow,
  }) async {
    final endpoint = Uri.parse('${config.baseUrl.replaceAll(RegExp(r'/+$'), '')}/audio/speech');
    final response = await http
        .post(
          endpoint,
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': config.model,
            'voice': config.voice,
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

String stripCodeFence(String text) {
  return text
      .replaceAll(RegExp(r'^\s*```(?:text|json|csv)?\s*', multiLine: false), '')
      .replaceAll(RegExp(r'\s*```\s*$', multiLine: false), '');
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

final questionBank = buildQuestionBank();
final dictationBank = buildDictationBank();

const chineseWordsByGrade = <int, List<String>>{
  1: ['天空', '太阳', '月亮', '白云', '小鸟', '大山', '河水', '花朵', '朋友', '同学', '老师', '书包', '铅笔', '认真', '快乐', '春天', '秋天', '上学', '写字', '读书'],
  2: ['明亮', '温暖', '勇敢', '仔细', '城市', '乡村', '森林', '草原', '海洋', '故事', '办法', '时候', '方向', '礼物', '教室', '操场', '希望', '幸福', '已经', '容易'],
  3: ['观察', '准备', '旅行', '诚实', '鼓励', '继续', '安静', '热闹', '漂亮', '奇妙', '忽然', '仍然', '愿望', '丰富', '保护', '节约', '整齐', '危险', '著名', '特别'],
  4: ['宽阔', '敏捷', '均匀', '规律', '痕迹', '幻想', '改善', '探索', '凝视', '舒适', '联系', '判断', '解释', '欣赏', '尊重', '坚强', '熟悉', '陌生', '创造', '责任'],
  5: ['清晰', '协调', '谨慎', '奉献', '启发', '实践', '比较', '控制', '效率', '资料', '范围', '推测', '准确', '平衡', '维护', '独立', '珍惜', '普通', '灿烂', '辽阔'],
  6: ['徘徊', '严峻', '领域', '贡献', '诞生', '锻炼', '毅力', '目标', '抉择', '荣誉', '挫折', '真理', '信念', '陶醉', '慷慨', '渺小', '浏览', '抵御', '沉着', '卓越'],
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
    for (var i = 1; i <= 70; i++) {
      final a = grade * 3 + i;
      final b = grade + i % 9 + 1;
      final answer = grade <= 2 ? a + b : (i.isEven ? a * b : a + b * grade);
      final expression = grade <= 2 ? '$a + $b' : (i.isEven ? '$a × $b' : '$a + $b × $grade');
      questions.add(PracticeQuestion(
        id: 'math_${grade}_$i',
        subject: Subject.math,
        grade: grade,
        question: '$expression = ?',
        options: makeNumberOptions(answer),
        answer: '$answer',
        explanation: '按运算顺序计算 $expression。',
      ));
    }
    final cnWords = chineseWordsByGrade[grade]!;
    for (var i = 0; i < 70; i++) {
      final word = cnWords[i % cnWords.length];
      final options = <String>[];
      for (var offset = 0; offset < 4; offset++) {
        options.add(cnWords[(i + offset) % cnWords.length]);
      }
      while (options.length < 4) {
        options.add(cnWords[(options.length + i + 3) % cnWords.length]);
      }
      questions.add(PracticeQuestion(id: 'chinese_${grade}_$i', subject: Subject.chinese, grade: grade, question: '下面哪个词语适合听写复习？', options: options, answer: word, explanation: '$word 是 $grade 年级常用词。'));
    }
    final enWords = englishWordsByGrade[grade]!;
    final entries = enWords.entries.toList();
    for (var i = 0; i < 70; i++) {
      final entry = entries[i % entries.length];
      questions.add(PracticeQuestion(id: 'english_${grade}_$i', subject: Subject.english, grade: grade, question: '${entry.key} 的中文意思是？', options: makeMeaningOptions(entry.value), answer: entry.value, explanation: '${entry.key} 表示${entry.value}。'));
    }
  }
  return questions;
}

List<String> makeNumberOptions(int answer) {
  final values = <int>{answer, answer + 1, answer + 3, max(0, answer - 2)}.toList()..sort();
  return values.map((value) => '$value').toList();
}

List<String> makeMeaningOptions(String answer) {
  final pool = englishVocabulary.map((item) => item.meaning).where((item) => item != answer).toList();
  final values = <String>{answer, ...pool.where((item) => item != answer).take(3)};
  return values.take(4).toList();
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
        FutureBuilder<RewardProfile>(
          future: LocalStore.loadRewards(),
          builder: (context, snapshot) {
            final rewards = snapshot.data ?? RewardProfile.empty;
            return AppPanel(
              icon: Icons.workspace_premium_outlined,
              title: '学习成长',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${rewards.title}  等级 ${rewards.level}'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: rewards.currentLevelPoints / 100),
                  const SizedBox(height: 8),
                  Text('积分 ${rewards.points}，连续学习 ${rewards.streak} 天，满分 ${rewards.perfect} 次'),
                ],
              ),
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
                if (_subject == Subject.english) ...[
                  AppPanel(
                    icon: Icons.style_outlined,
                    title: '背单词',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('本年级共享词库 ${englishVocabulary.where((item) => item.grade == _grade).length} 个词，练习、听写和背单词共用。'),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => WordStudyPage(grade: _grade)),
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
                AppPanel(
                  icon: Icons.document_scanner_outlined,
                  title: '导入题库',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('可以手动输入题目，也可以用已配置的 AI API 识别图片并整理成题库格式。'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _openQuestionImport(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('拍照 AI 导入'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _openQuestionImport(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('相册 AI 导入'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _openQuestionImport(null),
                            icon: const Icon(Icons.edit_note_outlined),
                            label: const Text('手动录入'),
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

  Future<void> _openQuestionImport(ImageSource? source) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuestionImportPage(
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

class WordStudyPage extends StatefulWidget {
  const WordStudyPage({required this.grade, super.key});

  final int grade;

  @override
  State<WordStudyPage> createState() => _WordStudyPageState();
}

class _WordStudyPageState extends State<WordStudyPage> {
  final _tts = AppTtsService();
  late final List<EnglishWord> _words = englishVocabulary.where((item) => item.grade == widget.grade).toList();
  int _index = 0;
  bool _showMeaning = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrent());
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final word = _words[_index];
    return Scaffold(
      appBar: AppBar(title: Text('${widget.grade} 年级背单词')),
      body: ListView(
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
                        ? Text(word.meaning, key: ValueKey(word.word), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700))
                        : Text('点击显示中文', key: ValueKey('${word.word}_hidden'), style: Theme.of(context).textTheme.titleLarge),
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
                onPressed: _index == _words.length - 1 ? null : _next,
                child: const Text('下一个'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _speakCurrent() async {
    try {
      await _tts.speak(text: _words[_index].word, language: Subject.english.ttsLanguage, slow: false);
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
    setState(() {
      _index--;
      _showMeaning = true;
    });
    _speakCurrent();
  }

  void _next() {
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

  @override
  Widget build(BuildContext context) {
    final questions = questionBank.where((item) => item.subject == _subject && item.grade == _grade).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle(icon: Icons.sports_esports_outlined, title: '学习游戏', subtitle: '从题库抽题闯关，完成后获得积分'),
        const SizedBox(height: 20),
        SubjectSelector(value: _subject, onChanged: (value) => setState(() => _subject = value)),
        const SizedBox(height: 18),
        GradeSelector(value: _grade, onChanged: (value) => setState(() => _grade = value)),
        const SizedBox(height: 18),
        AppPanel(
          icon: Icons.bolt_outlined,
          title: '快速闯关',
          child: Text('从 ${questions.length} 道题中抽取 10 道。答对越多，积分越高。'),
        ),
        const SizedBox(height: 12),
        AppPanel(
          icon: Icons.military_tech_outlined,
          title: '满分挑战',
          child: const Text('目标是 10 道全对，满分会额外增加奖励积分。'),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: questions.isEmpty
              ? null
              : () {
                  final picked = [...questions]..shuffle(Random());
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuizPage(subject: _subject, grade: _grade, questions: picked.take(10).toList()),
                    ),
                  );
                },
          icon: const Icon(Icons.play_arrow),
          label: const Text('开始闯关'),
        ),
      ],
    );
  }
}

class _DictationEntryPageState extends State<DictationEntryPage> {
  Subject _subject = Subject.chinese;
  int _grade = 1;
  int _autoNextSeconds = 0;
  int _itemCount = 10;
  late Future<List<DictationItem>> _customFuture = LocalStore.loadCustomDictation();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle(icon: Icons.record_voice_over_outlined, title: '听写训练', subtitle: '使用手机自带 TTS 朗读'),
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
            final items = allItems.take(_itemCount).toList();
            final customCount = items.where((item) => item.id.startsWith('custom_')).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPanel(
                  icon: Icons.hearing_outlined,
                  title: '听写说明',
                  child: Text(
                    '本次听写 ${items.length} 个，可选总量 ${allItems.length} 个，其中自定义 $customCount 个。'
                    '孩子写在纸上，结束后家长勾选对错。',
                  ),
                ),
                const SizedBox(height: 18),
                AppPanel(
                  icon: Icons.document_scanner_outlined,
                  title: '导入听写本',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('可以手动输入词语，也可以用已配置的 AI API 识别图片并整理成听写内容。'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () => _openDictationImport(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('拍照 AI 导入'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _openDictationImport(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('相册 AI 导入'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _openDictationImport(null),
                            icon: const Icon(Icons.edit_note_outlined),
                            label: const Text('手动录入'),
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
                              builder: (_) => DictationSessionPage(
                                subject: _subject,
                                grade: _grade,
                                items: items,
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

  Future<void> _openDictationImport(ImageSource? source) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DictationImportPage(
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

class QuestionImportPage extends StatefulWidget {
  const QuestionImportPage({
    required this.initialSubject,
    required this.initialGrade,
    required this.source,
    super.key,
  });

  final Subject initialSubject;
  final int initialGrade;
  final ImageSource? source;

  @override
  State<QuestionImportPage> createState() => _QuestionImportPageState();
}

class _QuestionImportPageState extends State<QuestionImportPage> {
  final _picker = ImagePicker();
  final _rawController = TextEditingController();
  late Subject _subject = widget.initialSubject;
  late int _grade = widget.initialGrade;
  bool _importing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (widget.source != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickAndAnalyze());
    }
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
            icon: widget.source == null
                ? Icons.edit_note_outlined
                : widget.source == ImageSource.camera
                    ? Icons.photo_camera_outlined
                    : Icons.photo_library_outlined,
            title: widget.source == null
                ? '手动录入'
                : widget.source == ImageSource.camera
                    ? '拍照 AI 导入'
                    : '相册 AI 导入',
            subtitle: 'AI 会整理文本，保存前仍可手动编辑',
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
              'AI 整理后请先检查文字，再保存。',
            ),
          ),
          const SizedBox(height: 16),
          if (_importing)
            const AppPanel(
              icon: Icons.auto_awesome_outlined,
              title: '正在用 AI 整理',
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
                  onPressed: _importing || widget.source == null ? null : _pickAndAnalyze,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('重新 AI 导入'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: questions.isEmpty || _importing ? null : () => _save(questions),
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

  Future<void> _pickAndAnalyze() async {
    setState(() {
      _importing = true;
      _message = null;
    });

    try {
      final config = await LocalStore.loadAiConfig();
      if (!config.isReady) {
        throw const FormatException('请先到设置中填写并开启 AI API 渠道。');
      }
      final image = await _picker.pickImage(source: widget.source!, imageQuality: 92);
      if (image == null) {
        if (mounted) {
          setState(() {
            _importing = false;
            _message = '没有选择图片。';
          });
        }
        return;
      }

      final text = await AiImportService.analyzeImage(
        config: config,
        image: image,
        instruction: '请识别图片中的小学${_subject.label}$_grade年级练习题，并整理成纯文本。'
            '每行一道题。选择题格式：题目|选项1|选项2|选项3|选项4|答案|解析。'
            '填空题格式：题目=答案。不要输出解释说明，不要输出 Markdown。',
      );

      if (mounted) {
        setState(() {
          _rawController.text = text;
          _importing = false;
          _message = text.isEmpty ? '没有识别到文字，请换一张更清晰的图片。' : null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _importing = false;
          _message = 'AI 导入失败：$error';
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

class DictationImportPage extends StatefulWidget {
  const DictationImportPage({
    required this.initialSubject,
    required this.initialGrade,
    required this.source,
    super.key,
  });

  final Subject initialSubject;
  final int initialGrade;
  final ImageSource? source;

  @override
  State<DictationImportPage> createState() => _DictationImportPageState();
}

class _DictationImportPageState extends State<DictationImportPage> {
  final _picker = ImagePicker();
  final _rawController = TextEditingController();
  late Subject _subject = widget.initialSubject;
  late int _grade = widget.initialGrade;
  bool _importing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    if (widget.source != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickAndAnalyze());
    }
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
            icon: widget.source == null
                ? Icons.edit_note_outlined
                : widget.source == ImageSource.camera
                    ? Icons.photo_camera_outlined
                    : Icons.photo_library_outlined,
            title: widget.source == null
                ? '手动录入'
                : widget.source == ImageSource.camera
                    ? '拍照 AI 导入'
                    : '相册 AI 导入',
            subtitle: 'AI 会整理词语，保存前仍可手动编辑',
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
          if (_importing)
            const AppPanel(
              icon: Icons.auto_awesome_outlined,
              title: '正在用 AI 整理',
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
                  onPressed: _importing || widget.source == null ? null : _pickAndAnalyze,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('重新 AI 导入'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: words.isEmpty || _importing ? null : () => _save(words),
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

  Future<void> _pickAndAnalyze() async {
    setState(() {
      _importing = true;
      _message = null;
    });

    try {
      final config = await LocalStore.loadAiConfig();
      if (!config.isReady) {
        throw const FormatException('请先到设置中填写并开启 AI API 渠道。');
      }
      final image = await _picker.pickImage(source: widget.source!, imageQuality: 92);
      if (image == null) {
        if (mounted) {
          setState(() {
            _importing = false;
            _message = '没有选择图片。';
          });
        }
        return;
      }

      final text = await AiImportService.analyzeImage(
        config: config,
        image: image,
        instruction: _subject == Subject.english
            ? '请识别图片中的小学英语$_grade年级单词或短语，整理为纯文本，每行一个英文单词或短语。不要输出中文解释，不要输出 Markdown。'
            : '请识别图片中的小学语文$_grade年级听写词语，整理为纯文本，每行一个词语。不要输出拼音、解释、序号或 Markdown。',
      );

      if (mounted) {
        setState(() {
          _rawController.text = text;
          _importing = false;
          _message = text.isEmpty ? '没有识别到文字，请换一张更清晰的图片。' : null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _importing = false;
          _message = 'AI 导入失败：$error';
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
            sentence: '来自手动录入或 AI 图片导入。',
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
      await _tts.speak(text: item.text, language: widget.subject.ttsLanguage, slow: _slow);
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
        const PageTitle(icon: Icons.settings_outlined, title: '设置', subtitle: '手机自带 TTS 和 API 兜底'),
        const SizedBox(height: 16),
        AppPanel(
          icon: Icons.volume_up_outlined,
          title: '手机自带 TTS 测试',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('朗读效果由手机自带语音引擎决定。若无法朗读，请在手机设置中安装中文或英文语音包。'),
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
        FutureBuilder<TtsApiConfig>(
          future: _ttsFuture,
          builder: (context, snapshot) {
            final config = snapshot.data ?? TtsApiConfig.empty;
            return AppPanel(
              icon: Icons.graphic_eq_outlined,
              title: 'TTS API 兜底',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(config.isReady ? '已开启：${config.model} / ${config.voice}' : '默认使用手机自带 TTS。手机自带 TTS 不可用时，可配置 OpenAI 格式 TTS API。'),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _openTtsApiSettings,
                    icon: const Icon(Icons.tune_outlined),
                    label: const Text('配置 TTS API'),
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
                  Text(config.isReady ? '已开启：${config.model}' : '未开启。可用于拍照整理题库和听写词。'),
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
    try {
      await _tts.speak(text: text, language: language, slow: false);
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

  Future<void> _openTtsApiSettings() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TtsApiSettingsPage()));
    if (mounted) {
      setState(() => _ttsFuture = LocalStore.loadTtsApiConfig());
    }
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
            title: const Text('启用 AI 图片导入'),
            subtitle: const Text('开启后，选择的图片会发送到你配置的 AI API。'),
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
            title: const Text('启用 TTS API 兜底'),
            subtitle: const Text('优先使用手机自带 TTS；手机自带 TTS 报错时才调用这里配置的 OpenAI 格式 /audio/speech。'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _baseUrl, decoration: const InputDecoration(labelText: 'Base URL', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _model, decoration: const InputDecoration(labelText: 'TTS 模型', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _voice, decoration: const InputDecoration(labelText: 'Voice', border: OutlineInputBorder())),
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
