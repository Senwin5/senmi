import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../registration/auth/login.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  int currentPage = 0;

  late AnimationController _animController;
  late Animation<double> _animation;

  final List<Map<String, String>> pages = [
    {
      "title": "Fast Delivery",
      "desc": "Send packages across town quickly and safely.",
      "image": "assets/onboarding/delivery1.png",
    },
    {
      "title": "Real-time Tracking",
      "desc": "Track your deliveries live anytime.",
      "image": "assets/onboarding/delivery2.png",
    },
    {
      "title": "Secure & Reliable",
      "desc": "Your packages are always safe with us.",
      "image": "assets/onboarding/delivery3.png",
    },
  ];

  @override
  void initState() {
    super.initState();

    // Animation for images
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    startAutoSlide();
  }

  void startAutoSlide() {
    Future.delayed(const Duration(seconds: 4), () {
      if (_controller.hasClients) {
        int nextPage = currentPage + 1;
        if (nextPage < pages.length) {
          _controller.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        startAutoSlide();
      }
    });
  }

  void nextPage() {
    if (currentPage < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  // ✅ Mark onboarding as completed
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() => currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _animation.value),
                                child: child,
                              );
                            },
                            child: Image.asset(
                              pages[index]['image']!,
                              height: 180,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            pages[index]['title']!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5F5FFF),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            pages[index]['desc']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.all(4),
                    width: currentPage == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentPage == index
                          ? const Color(0xFF5F5FFF)
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5F5FFF),
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: nextPage,
                    child: Text(
                      currentPage == pages.length - 1 ? "Get Started" : "Next",
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () {
                _controller.jumpToPage(pages.length - 1);
              },
              child: const Text(
                "Skip",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}