import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiscoveryTestPage extends StatefulWidget {
  const DiscoveryTestPage({super.key});

  @override
  State<DiscoveryTestPage> createState() => _DiscoveryTestPageState();
}

class _DiscoveryTestPageState extends State<DiscoveryTestPage>
    with SingleTickerProviderStateMixin {
  static const Color _bgStart = Color(0xFF0B1120);
  static const Color _bgMiddle = Color(0xFF0F172A);
  static const Color _bgEnd = Color(0xFF1E1B4B);
  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _blue = Color(0xFF0EA5E9);
  static const Color _purple = Color(0xFF7C3AED);

  final List<_Question> _questions = const [
    _Question(
      id: 0,
      question: 'How do you prefer to learn new skills?',
      options: [
        'Hands-on practice and experimentation',
        'Structured courses with clear milestones',
        'One-on-one mentorship and guidance',
        'Self-paced learning with resources',
      ],
      category: 'Learning Style',
    ),
    _Question(
      id: 1,
      question: "What's your current coding proficiency?",
      options: [
        'Beginner - Learning fundamentals',
        'Intermediate - Building projects',
        'Advanced - Professional experience',
        'Expert - Teaching and mentoring others',
      ],
      category: 'Technical Skills',
    ),
    _Question(
      id: 2,
      question: 'How would you rate your English communication?',
      options: [
        'Basic - Simple conversations',
        'Intermediate - Can discuss most topics',
        'Advanced - Fluent and nuanced',
        'Native/Professional - Complex discussions',
      ],
      category: 'Language Skills',
    ),
    _Question(
      id: 3,
      question: "What's your availability for skill swapping?",
      options: [
        '1-2 hours per week',
        '3-5 hours per week',
        '5-10 hours per week',
        'Flexible schedule',
      ],
      category: 'Commitment',
    ),
    _Question(
      id: 4,
      question: 'Which skill would you most like to teach?',
      options: [
        'Guitar and music theory',
        'Web development and coding',
        'English language and writing',
        'Design and creative tools',
      ],
      category: 'Teaching Interest',
    ),
  ];

  int _currentQuestion = 0;
  final Map<int, String> _answers = {};
  String? _selectedOption;
  Timer? _nextTimer;
  late final AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    _backgroundController.dispose();
    super.dispose();
  }

  double get _progress =>
      ((_currentQuestion + 1) / _questions.length) * 100;

  void _handleAnswer(String option) {
    setState(() {
      _selectedOption = option;
    });

    _nextTimer?.cancel();
    _nextTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      _answers[_currentQuestion] = option;

      if (_currentQuestion < _questions.length - 1) {
        setState(() {
          _currentQuestion++;
          _selectedOption = null;
        });
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/profile');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_bgStart, _bgMiddle, _bgEnd],
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, _) {
                return Opacity(
                  opacity: 0.10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) {
                      final angle = math.sin(
                            (_backgroundController.value * 2 * math.pi) + i,
                          ) *
                          0.16;
                      return Transform.rotate(
                        angle: angle,
                        child: Container(
                          width: 3,
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [_cyan, _purple],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Column(
                      children: [
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.10),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.flash_on,
                                    size: 16,
                                    color: _cyan,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Heptapus Discovery',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return const LinearGradient(
                                  colors: [Colors.white, _cyan, _purple],
                                ).createShader(bounds);
                              },
                              child: const Text(
                                'Discover Your Profile',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Answer ${_questions.length} questions to find your perfect skill matches',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.50),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _ProgressBar(progress: _progress),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${_currentQuestion + 1} of ${_questions.length}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.50),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${_progress.round()}%',
                              style: const TextStyle(
                                color: _cyan,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(animation);

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                        child: _QuestionCard(
                          key: ValueKey(question.id),
                          question: question,
                          selectedOption: _selectedOption,
                          onAnswer: _handleAnswer,
                        ),
                      ),
                    ),
                  ),
                  const IgnorePointer(
                    child: SizedBox(
                      height: 36,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [_bgStart, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final _Question question;
  final String? selectedOption;
  final ValueChanged<String> onAnswer;

  const _QuestionCard({
    super.key,
    required this.question,
    required this.selectedOption,
    required this.onAnswer,
  });

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Learning Style':
        return Icons.psychology_outlined;
      case 'Technical Skills':
        return Icons.gps_fixed;
      case 'Language Skills':
        return Icons.workspace_premium_outlined;
      case 'Commitment':
        return Icons.flash_on;
      case 'Teaching Interest':
        return Icons.track_changes;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.20),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: [
                  const Color(0x337C3AED),
                  const Color(0x3306B6D4),
                ],
              ),
              border: Border.all(
                color: const Color(0x4D7C3AED),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _categoryIcon(question.category),
                  size: 16,
                  color: _cyan,
                ),
                const SizedBox(width: 8),
                Text(
                  question.category,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.80),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            question.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Column(
              children: question.options.map((option) {
                final isSelected = selectedOption == option;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AnswerButton(
                    text: option,
                    isSelected: isSelected,
                    onTap: () => onAnswer(option),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.02 : 1,
      duration: const Duration(milliseconds: 180),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isSelected
                ? const LinearGradient(colors: [_purple, _cyan])
                : null,
            color: isSelected ? null : Colors.white.withOpacity(0.05),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.10),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.45),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  static const Color _cyan = Color(0xFF06B6D4);
  static const Color _blue = Color(0xFF0EA5E9);
  static const Color _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Container(
              color: Colors.white.withOpacity(0.05),
            ),
            FractionallySizedBox(
              widthFactor: progress / 100,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_cyan, _blue, _purple],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Question {
  final int id;
  final String question;
  final List<String> options;
  final String category;

  const _Question({
    required this.id,
    required this.question,
    required this.options,
    required this.category,
  });
}