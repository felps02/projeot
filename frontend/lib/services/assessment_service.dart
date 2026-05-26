import '../config/api_config.dart';
import '../models/assessment.dart';
import '../models/question.dart';
import '../models/answer.dart';
import 'api_service.dart';

class AssessmentService {
  final ApiService _api = ApiService();

  Future<({bool success, Assessment? assessment, String? message})> createAssessment({
    required String usuarioId,
    required List<Answer> respostas,
  }) async {
    final score = Assessment.calculateRiskScore(respostas);
    final nivel = Assessment.calculateRiskLevel(score);

    final response = await _api.post(
      ApiConfig.assessments,
      body: {
        'usuarioId': usuarioId,
        'data': DateTime.now().toIso8601String(),
        'scoreRisco': score,
        'nivelRisco': nivel,
        'completada': true,
        'respostas': respostas.map((r) => r.toJson()).toList(),
      },
    );

    if (response.success && response.data != null) {
      return (
        success: true,
        assessment: Assessment.fromJson(response.data),
        message: null,
      );
    }

    return (
      success: false,
      assessment: null,
      message: response.message ?? 'Erro ao enviar avaliacao',
    );
  }

  Future<List<Assessment>> getAssessments(String usuarioId) async {
    final response = await _api.get(
      '${ApiConfig.assessments}/$usuarioId',
    );

    if (response.success && response.data != null) {
      final list = response.data as List;
      return list.map((item) => Assessment.fromJson(item)).toList();
    }
    return [];
  }

  Future<bool> getTodayStatus(String usuarioId) async {
    final response = await _api.get(
      '${ApiConfig.todayStatus}/$usuarioId',
    );

    if (response.success && response.data != null) {
      return response.data['completada'] ?? false;
    }
    return false;
  }

  Future<List<Assessment>> getHistory(String usuarioId, {int? days}) async {
    final params = <String, String>{};
    if (days != null) params['dias'] = days.toString();

    final response = await _api.get(
      '${ApiConfig.assessmentHistory}/$usuarioId',
      queryParams: params.isNotEmpty ? params : null,
    );

    if (response.success && response.data != null) {
      final list = response.data as List;
      return list.map((item) => Assessment.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<Question>> getActiveQuestions() async {
    final response = await _api.get(ApiConfig.activeQuestions);

    if (response.success && response.data != null) {
      final list = response.data as List;
      return list.map((item) => Question.fromJson(item)).toList();
    }
    return Question.defaultQuestions();
  }
}
