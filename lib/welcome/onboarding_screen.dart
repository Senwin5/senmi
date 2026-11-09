// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:senmi/senmi_shared_account/registration/auth/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final Color primaryColor = const Color(0xFF581C87);
  final Color backgroundColor = const Color(0xFFF7F4FC);

  final List<Map<String, String>> pages = [
    {
      "title": "Fast Delivery",
      "desc": "Send packages across town quickly and safely.",
      "image": "assets/onboarding/delivery1.png",
    },
    {
      "title": "Real-time Tracking",
      "desc":
          "Track your deliveries live and stay updated every step of the way.",
      "image": "assets/onboarding/delivery2.png",
    },
    {
      "title": "Secure & Reliable",
      "desc":
          "Your packages are in safe hands. Enjoy reliable deliveries with Senmi.",
      "image": "assets/onboarding/delivery3.png",
    },
  ];

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    startAutoSlide();
  }

  // AUTOMATIC SLIDING
  void startAutoSlide() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;

      if (_controller.hasClients) {
        int next = currentPage + 1;

        if (next < pages.length) {
          _controller.animateToPage(
            next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }

      startAutoSlide();
    });
  }

  // NEXT PAGE
  void nextPage() {
    if (currentPage < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  // COMPLETE ONBOARDING
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;

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
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: Column(
          children: [
            // TOP HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  // SENMI LOGO
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SENMI",
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: primaryColor,
                        ),
                      ),

                      const Text(
                        "MOVE WHAT MATTERS",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  TextButton(
                    onPressed: () {
                      _controller.jumpToPage(pages.length - 1);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                    ),
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ONBOARDING PAGES
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,

                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },

                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),

                    child: Container(
                      width: double.infinity,

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),

                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.07),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),

                      child: Padding(
                        padding: const EdgeInsets.all(24),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            // ANIMATED ILLUSTRATION
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
                                height: 210,
                                fit: BoxFit.contain,
                              ),
                            ),

                            const SizedBox(height: 35),

                            // PAGE NUMBER
                            Text(
                              "0${index + 1} / 0${pages.length}",
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // TITLE
                            Text(
                              pages[index]['title']!,
                              textAlign: TextAlign.center,

                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // DESCRIPTION
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),

                              child: Text(
                                pages[index]['desc']!,
                                textAlign: TextAlign.center,

                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.7,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // PAGE INDICATORS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,

              children: List.generate(pages.length, (index) {
                final selected = currentPage == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),

                  margin: const EdgeInsets.symmetric(horizontal: 4),

                  width: selected ? 30 : 9,
                  height: 9,

                  decoration: BoxDecoration(
                    color: selected
                        ? primaryColor
                        : Colors.deepPurple.withOpacity(0.18),

                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),

            // NEXT / GET STARTED BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),

              child: SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton(
                  onPressed: nextPage,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,

                    elevation: 4,
                    shadowColor: primaryColor.withOpacity(0.3),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Text(
                        currentPage == pages.length - 1
                            ? "Get Started"
                            : "Next",

                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(width: 10),

                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // BOTTOM BRAND MESSAGE
            Padding(
              padding: const EdgeInsets.only(bottom: 12),

              child: Text(
                "Move  •  What  •  Matters",

                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
