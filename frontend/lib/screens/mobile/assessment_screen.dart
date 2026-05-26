import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/assessment_provider.dart';
import '../../widgets/mobile/emoji_selector.dart';
import '../../widgets/mobile/likert_scale.dart';
import '../../widgets/mobile/quick_select.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    context.read<AssessmentProvider>().loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final provider = context.read<AssessmentProvider>();
    if (_currentPage < provider.currentQuestions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final provider = context.read<AssessmentProvider>();
    final success = await provider.submitAssessment(user.id);

    if (!mounted) return;

    if (success) {
      _showCompletionDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erro ao enviar avaliacao'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCompletionDialog() {
    final provider = context.read<AssessmentProvider>();
    final assessment = provider.lastAssessment;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            BounceInDown(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.riskLow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: AppTheme.riskLow,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Avaliacao concluida!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Obrigado por compartilhar como voce esta. Sua saude mental importa!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            if (assessment != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Score: '),
                    Text(
                      assessment.scoreRisco.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(' pts'),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Voltar ao inicio'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final questions = provider.currentQuestions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliacao Diaria'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading && questions.isEmpty
          ? const Center(child: LoadingWidget())
          : Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pergunta ${_currentPage + 1} de ${questions.length}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            '${(((_currentPage + 1) / questions.length) * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: questions.isNotEmpty
                              ? (_currentPage + 1) / questions.length
                              : 0,
                          minHeight: 8,
                          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),

                // Questions
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                    },
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];

                      return FadeIn(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getCategoryLabel(question.categoria),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Question text
                              Text(
                                question.texto,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 40),
                              // Answer widget
                              _buildAnswerWidget(question.tipo, question.id),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: CustomButton(
                            text: 'Anterior',
                            onPressed: _previousPage,
                            isOutlined: true,
                            icon: Icons.arrow_back,
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _currentPage == questions.length - 1
                            ? CustomButton(
                                text: 'Enviar',
                                onPressed: provider.allQuestionsAnswered
                                    ? _submit
                                    : null,
                                isLoading: provider.isLoading,
                                icon: Icons.check_circle,
                                color: AppTheme.riskLow,
                              )
                            : CustomButton(
                                text: 'Proximo',
                                onPressed: provider.currentAnswers
                                        .containsKey(
                                            questions[_currentPage].id)
                                    ? _nextPage
                                    : null,
                                icon: Icons.arrow_forward,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAnswerWidget(String tipo, String questionId) {
    final provider = context.watch<AssessmentProvider>();
    final currentValue = provider.currentAnswers[questionId];

    switch (tipo) {
      case 'emoji':
        return EmojiSelector(
          selectedValue: currentValue,
          onSelected: (value) {
            provider.setAnswer(questionId, value);
          },
        );
      case 'likert':
        return LikertScale(
          selectedValue: currentValue,
          onSelected: (value) {
            provider.setAnswer(questionId, value);
          },
        );
      case 'sim_nao':
        return QuickSelect(
          selectedValue: currentValue,
          onSelected: (value) {
            provider.setAnswer(questionId, value);
          },
        );
      default:
        return LikertScale(
          selectedValue: currentValue,
          onSelected: (value) {
            provider.setAnswer(questionId, value);
          },
        );
    }
  }

  String _getCategoryLabel(String categoria) {
    switch (categoria) {
      case 'emocional':
        return 'Bem-estar Emocional';
      case 'estresse':
        return 'Nivel de Estresse';
      case 'ambiente':
        return 'Ambiente de Trabalho';
      case 'relacionamento':
        return 'Relacionamentos';
      case 'geral':
        return 'Saude Geral';
      default:
        return categoria;
    }
  }
}
