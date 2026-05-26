import 'package:flutter/material.dart';
import '../models/assessment.dart';
import '../models/question.dart';
import '../models/answer.dart';
import '../services/assessment_service.dart';

class AssessmentProvider extends ChangeNotifier {
  final AssessmentService _service = AssessmentService();

  List<Assessment> _assessments = [];
  List<Question> _currentQuestions = [];
  Map<String, int> _currentAnswers = {};
  bool _todayDone = false;
  bool _isLoading = false;
  String? _errorMessage;
  Assessment? _lastAssessment;

  List<Assessment> get assessments => _assessments;
  List<Question> get currentQuestions => _currentQuestions;
  Map<String, int> get currentAnswers => _currentAnswers;
  bool get todayDone => _todayDone;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Assessment? get lastAssessment => _lastAssessment;

  double get averageScore {
    if (_assessments.isEmpty) return 0;
    final total = _assessments.fold<double>(0, (sum, a) => sum + a.scoreRisco);
    return total / _assessments.length;
  }

  int get totalAssessments => _assessments.length;

  int get streakDays {
    if (_assessments.isEmpty) return 0;
    final sorted = List<Assessment>.from(_assessments)
      ..sort((a, b) => b.data.compareTo(a.data));

    int streak = 0;
    DateTime checkDate = DateTime.now();

    for (final assessment in sorted) {
      if (_isSameDay(assessment.data, checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (assessment.data.isBefore(checkDate)) {
        break;
      }
    }
    return streak;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> loadQuestions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentQuestions = await _service.getActiveQuestions();
      _currentAnswers = {};
    } catch (e) {
      _currentQuestions = Question.defaultQuestions();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setAnswer(String questionId, int value) {
    _currentAnswers[questionId] = value;
    notifyListeners();
  }

  bool get allQuestionsAnswered {
    return _currentQuestions.every(
      (q) => _currentAnswers.containsKey(q.id),
    );
  }

  Future<bool> submitAssessment(String usuarioId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final answers = _currentAnswers.entries.map((entry) {
      return Answer(
        perguntaId: entry.key,
        valor: entry.value,
      );
    }).toList();

    final result = await _service.createAssessment(
      usuarioId: usuarioId,
      respostas: answers,
    );

    if (result.success && result.assessment != null) {
      _lastAssessment = result.assessment;
      _todayDone = true;
      _currentAnswers = {};
      _assessments.insert(0, result.assessment!);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = result.message;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> loadHistory(String usuarioId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _assessments = await _service.getHistory(usuarioId);
      if (_assessments.isNotEmpty) {
        _lastAssessment = _assessments.first;
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar historico';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkToday(String usuarioId) async {
    try {
      _todayDone = await _service.getTodayStatus(usuarioId);
    } catch (_) {
      _todayDone = false;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _assessments = [];
    _currentQuestions = [];
    _currentAnswers = {};
    _todayDone = false;
    _lastAssessment = null;
    notifyListeners();
  }
}
