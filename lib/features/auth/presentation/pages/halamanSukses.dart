import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/localization/app_localizations.dart';
import '../widgets/tombolUtama.dart';
import '../widgets/indikatorLangkah.dart';

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  List<String> _stepLabels(BuildContext context) {
    return [
      tr(context, 'step_create_account'),
      tr(context, 'step_password'),
      tr(context, 'step_profile_photo'),
      tr(context, 'step_success'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(context, 'welcome_workfra'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  height: 1.3,
                ),
              ),
              StepIndicator(currentStep: 3, labels: _stepLabels(context)),
              const Spacer(),
              Center(
                child: Lottie.asset(
                  'assets/animations/Smiling Owl.json',
                  width: 250,
                  height: 250,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  tr(context, 'success_account_created'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                    height: 1.6,
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: tr(context, 'continue'),
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/home', (route) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
