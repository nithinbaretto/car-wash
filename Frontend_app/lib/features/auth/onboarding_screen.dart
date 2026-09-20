import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/buttons.dart';
import 'role_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const route = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      title: 'Tired of\nwaiting in line?',
      body:
          'Find nearby car washes,\ncheck live availability and\nbook your slot in minutes.',
      imageAsset: AppAssets.onboardingStep1,
    ),
    _OnboardPage(
      title: 'Book your\nCar wash, smarter.',
      body:
          'See real-time availability,\nchoose your preferred time\nand get on the road.',
      imageAsset: AppAssets.onboardingStep2,
    ),
    _OnboardPage(
      title: 'Clean cars.\nHappier drives.',
      body: '',
      art: _BenefitsArt(),
    ),
  ];

  void _next() {
    if (_page == _pages.length - 1) {
      Navigator.of(context).pushNamed(RoleScreen.route);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _skip() {
    Navigator.of(context).pushNamed(RoleScreen.route);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
              child: SizedBox(
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _Dots(index: _page, count: _pages.length),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _skip,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          child: Text(
                            'Skip',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              color: const Color(0xCC103157),
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            page.title,
                            style: GoogleFonts.montserrat(
                              fontSize: 36,
                              height: 1,
                              letterSpacing: 36 * -0.02,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          if (page.body.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              page.body,
                              style: GoogleFonts.montserrat(
                                fontSize: 20,
                                height: 1.22,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onboardingBody,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: page.imageAsset != null
                          ? Image.asset(
                              page.imageAsset!,
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.bottomCenter,
                              width: double.infinity,
                              filterQuality: FilterQuality.high,
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: page.art ?? const SizedBox.shrink(),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _page == 0
                      ? AppPrimaryButton(
                          width: 292,
                          label: 'Next  >',
                          onPressed: _next,
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppBackCircle(
                              size: 52,
                              onTap: () => _controller.previousPage(
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOut,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppPrimaryButton(
                              width: 313,
                              label: last ? 'Get started' : 'Next',
                              onPressed: _next,
                            ),
                          ],
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

class _OnboardPage {
  const _OnboardPage({
    required this.title,
    required this.body,
    this.art,
    this.imageAsset,
  });

  final String title;
  final String body;
  final Widget? art;
  final String? imageAsset;
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
          width: active ? 22 : 16,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFFD5DCE5),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _BenefitsArt extends StatelessWidget {
  const _BenefitsArt();

  @override
  Widget build(BuildContext context) {
    const items = [
      (AppAssets.benefitVerified, 'Verified car washes', 'Trusted local businesses'),
      (AppAssets.benefitClock, 'Line availability', 'No more guessing'),
      (AppAssets.benefitFav, 'Save your favourites', 'Your go-to-car washes'),
      (AppAssets.benefitStar, 'Rate and support', 'Help others find great service'),
    ];
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 22),
      itemBuilder: (context, index) {
        final item = items[index];
        return Row(
          children: [
            Image.asset(
              item.$1,
              width: 75,
              height: 75,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$2,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      height: 1.22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    item.$3,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      height: 1.22,
                      fontWeight: FontWeight.w500,
                      color: const Color(0x96000000),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
