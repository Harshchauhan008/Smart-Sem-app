
import 'package:flutter/material.dart';
import '../helper/global.dart';
import '../helper/pref.dart';
import '../model/onboard.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color navy = Color(0xFF0B3D91);
  static const Color blue = Color(0xFF3B82F6);

  final List<Onboard> _pages = const [
    Onboard(
      title: 'Smart Learning Made Easy',
      subtitle:
      'Access your timetable, attendance, assignments, study materials and more — all in one place.',
      image: 'calendar',
    ),
    Onboard(
      title: 'Meet Your AI Study Buddy',
      subtitle:
      'Ask academic questions, understand difficult topics and get help with your study materials.',
      image: 'ai',
    ),
    Onboard(
      title: 'Stay Organized, Stay Ahead',
      subtitle:
      'Keep track of deadlines, classes and academic reminders without missing what matters.',
      image: 'organize',
    ),
  ];

  IconData _pageIcon(String image) {
    switch (image) {
      case 'calendar':
        return Icons.calendar_month_rounded;
      case 'ai':
        return Icons.smart_toy_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  Future<void> _finishOnboarding() async {
    Pref.showOnboarding = false;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = screenSize(context).width;
    final isWide = width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 40 : 24,
                vertical: 12,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: blue),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        final page = _pages[index];

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: isWide ? 300 : 260,
                              height: isWide ? 280 : 250,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5F0FF),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 175,
                                    height: 175,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFD0E4FF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Icon(
                                    _pageIcon(page.image),
                                    size: 110,
                                    color: navy,
                                  ),
                                  Positioned(
                                    right: 32,
                                    top: 38,
                                    child: Icon(
                                      Icons.auto_awesome,
                                      color: blue,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 38),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF0F172A),
                                fontSize: isWide ? 28 : 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? blue
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
