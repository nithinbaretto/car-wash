import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
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
          'Find nearby car washes, check live availability and book your slot in minutes.',
      imageAsset: AppAssets.onboardingStep1,
    ),
    _OnboardPage(
      title: 'Book your\nCar wash, smarter.',
      body:
          'See real-time availability, choose your preferred time and get on the road.',
      imageAsset: AppAssets.onboardingStep2,
    ),
    _OnboardPage(
      title: 'Clean cars.\nHappier drives.',
      body:
          'Verified shops, live wait times, saved favourites and real reviews in one place.',
    ),
  ];

  void _next() {
    if (_page == _pages.length - 1) {
      Navigator.of(context).pushNamed(RoleScreen.route);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
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
    final current = _pages[_page];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
                child: Row(
                  children: [
                    _PageIndex(
                      index: _page,
                      count: _pages.length,
                    ),
                    const Spacer(),
                    if (!last)
                      TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          'Skip',
                          style: AppText.ui(
                            size: 15,
                            weight: FontWeight.w600,
                            height: 1,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  return _HeroPane(page: _pages[index]);
                },
              ),
            ),
            _ContentSheet(
              title: current.title,
              body: current.body,
              page: _page,
              count: _pages.length,
              last: last,
              onBack: _page == 0 ? null : _back,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPane extends StatelessWidget {
  const _HeroPane({required this.page});

  final _OnboardPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F3FC),
              Colors.white,
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140C3D73),
              blurRadius: 28,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: page.imageAsset != null
              ? Image.asset(
                  page.imageAsset!,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  width: double.infinity,
                  height: double.infinity,
                  filterQuality: FilterQuality.high,
                )
              : const Padding(
                  padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: _BenefitsArt(),
                ),
        ),
      ),
    );
  }
}

class _ContentSheet extends StatelessWidget {
  const _ContentSheet({
    required this.title,
    required this.body,
    required this.page,
    required this.count,
    required this.last,
    required this.onNext,
    this.onBack,
  });

  final String title;
  final String body;
  final int page;
  final int count;
  final bool last;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A0D2B4A),
            blurRadius: 24,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dots(index: page, count: count),
              const SizedBox(height: 20),
              SizedBox(
                height: 154,
                width: double.infinity,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  child: SizedBox(
                    key: ValueKey(page),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppText.display(
                            size: 32,
                            height: 1.12,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          body.isEmpty ? ' ' : body,
                          style: AppText.ui(
                            size: 16,
                            height: 1.45,
                            weight: FontWeight.w500,
                            color: body.isEmpty
                                ? Colors.transparent
                                : AppColors.onboardingBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: AppButtons.height,
                child: onBack == null
                    ? AppPrimaryButton(
                        label: 'Next',
                        trailing: const Icon(Icons.arrow_forward_rounded),
                        onPressed: onNext,
                      )
                    : Row(
                        children: [
                          AppBackCircle(size: 56, onTap: onBack),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppPrimaryButton(
                              label: last ? 'Get started' : 'Next',
                              trailing: last
                                  ? null
                                  : const Icon(Icons.arrow_forward_rounded),
                              onPressed: onNext,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndex extends StatelessWidget {
  const _PageIndex({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final step = (index + 1).toString().padLeft(2, '0');
    final total = count.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$step / $total',
        style: AppText.ui(
          size: 12,
          weight: FontWeight.w700,
          letterSpacing: 0.8,
          height: 1,
          color: AppColors.primaryDeep,
        ),
      ),
    );
  }
}

class _OnboardPage {
  const _OnboardPage({
    required this.title,
    required this.body,
    this.imageAsset,
  });

  final String title;
  final String body;
  final String? imageAsset;
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.only(right: i == count - 1 ? 0 : 6),
          height: 6,
          width: active ? 28 : 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.border,
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

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: _BenefitRow(
              asset: items[i].$1,
              title: items[i].$2,
              subtitle: items[i].$3,
              index: i,
              isLast: i == items.length - 1,
            ),
          ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.index,
    required this.isLast,
  });

  final String asset;
  final String title;
  final String subtitle;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Column(
            children: [
              Image.asset(
                asset,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              if (!isLast)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppText.ui(
                          size: 16,
                          height: 1.2,
                          weight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      (index + 1).toString().padLeft(2, '0'),
                      style: AppText.ui(
                        size: 11,
                        weight: FontWeight.w700,
                        letterSpacing: 0.6,
                        height: 1,
                        color: AppColors.mutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppText.ui(
                    size: 13,
                    height: 1.35,
                    weight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
