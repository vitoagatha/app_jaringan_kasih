import 'package:flutter/material.dart';

import '../../../core/presentation/app_layout.dart';

class StartupSplash extends StatelessWidget {
  const StartupSplash({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          width: double.infinity,
          color: const Color(0xFF20A0A6),
          alignment: Alignment.center,
          child: SafeArea(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset('assets/images/icon_splash.png',
                  width: 300, height: 300, semanticLabel: 'Jaringan Kasih'),
              const SizedBox(height: 28),
              const CircularProgressIndicator(
                  color: Colors.white, semanticsLabel: 'Memeriksa sesi'),
            ]),
          ),
        ),
      );
}

class WelcomeOnboarding extends StatelessWidget {
  final VoidCallback onContinue;
  const WelcomeOnboarding({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: AppContent(
            maxWidth: 560,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  Row(children: [
                    Text('Jaringan Kasih',
                        style: Theme.of(context).textTheme.titleLarge),
                  ]),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/welcome_screens1.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        semanticLabel: 'Kegiatan berbagi dan pendampingan',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Semua dapat membantu',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 10),
                  Text(
                    'Temukan pendanaan yang berarti dan dukung komunitas untuk tumbuh bersama.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('onboarding_continue'),
                      onPressed: onContinue,
                      child: const Text('Mulai sekarang'),
                    ),
                  ),
                  TextButton(
                    onPressed: onContinue,
                    child: const Text('Lewati'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
