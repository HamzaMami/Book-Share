import 'package:flutter/material.dart';
import 'package:bookshare/components/default_button.dart';
import 'package:bookshare/views/auth/sign_in_screen.dart';
import 'package:bookshare/views/auth/sign_up_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'image': 'assets/onboard-1.png',
      'title': 'Only Books Can Help You',
      'description': 'Books can help you to increase your knowledge and become more successfully.',
    },
    {
      'image': 'assets/onboard-2.png',
      'title': 'Learn Smartly',
      'description': 'Welcome to BookShare. It is 2026, time to learn smarter, not harder. Your entire library is now in the cloud, accessible instantly from your phone.',
    },
    {
      'image': 'assets/onboard-3.png',
      'title': 'Start Your Journey',
      'description': 'Begin your reading adventure and explore countless amazing stories.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
              );
            },
            child: const Text(
              'Skip',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ),
          SizedBox(width:24 ),
        ],
      ),
      body: Stack(
        children: [
          // Skip button

          // PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: onboardingData.length,
            itemBuilder: (context, index) {
              final bool isLastSlide = index == onboardingData.length - 1;

              return SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        Expanded(
                          flex: 6,
                          child: SizedBox(
                            width: double.infinity,
                            child: Image.asset(
                              onboardingData[index]['image']!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 78),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  onboardingData[index]['title']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  onboardingData[index]['description']!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                if (isLastSlide) const SizedBox(height: 20),
                                if (isLastSlide)
                                  DefaultButton(
                                    text: 'Get Started Now',
                                    pressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const SignUpScreen(),
                                        ),
                                      );
                                    },
                                    activated: true,
                                    loading: false,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          // Dynamic Page Indicator Dots
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 10,
                  height: _currentPage == index ? 12 : 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.blue : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}