import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: AppColors.black, width: 2),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: AppColors.black, offset: Offset(5, 5)),
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: controller.skip,
                        child: Text(
                          'Skip',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: controller.pageController,
                        itemCount: controller.items.length,
                        onPageChanged: controller.onPageChanged,
                        itemBuilder: (context, index) {
                          final item = controller.items[index];
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxHeight < 460;
                              final illustrationSize = compact ? 170.0 : 250.0;
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Padding(
                                  key: ValueKey<int>(index),
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    0,
                                    24,
                                    0,
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      SizedBox(height: compact ? 8 : 20),
                                      _OnboardingIllustration(
                                        icon: item.icon,
                                        blobColor: item.blobColor,
                                        circleColor: item.circleColor,
                                        size: illustrationSize,
                                      ),
                                      SizedBox(height: compact ? 14 : 24),
                                      Text(
                                        item.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall
                                            ?.copyWith(
                                              fontSize: compact ? 42 : 50,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: Text(
                                          item.description,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          controller.items.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: controller.currentPage.value == index
                                ? 36
                                : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Obx(
                        () => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.nextOrFinish,
                            child: Text(
                              controller.isLastPage ? 'GET STARTED' : 'NEXT',
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
        ),
      ),
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({
    required this.icon,
    required this.blobColor,
    required this.circleColor,
    required this.size,
  });

  final IconData icon;
  final Color blobColor;
  final Color circleColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final blobWidth = size * 0.9;
    final blobHeight = size * 0.72;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            bottom: size * 0.1,
            child: Container(
              width: blobWidth,
              height: blobHeight,
              decoration: BoxDecoration(
                color: blobColor,
                borderRadius: BorderRadius.circular(size * 0.35),
              ),
            ),
          ),
          Positioned(
            top: size * 0.14,
            child: Transform.rotate(
              angle: -math.pi / 12,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: circleColor, width: 2),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.06,
            child: Container(
              width: size * 0.56,
              height: size * 0.56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.black, width: 1.5),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/images/logo-app.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
