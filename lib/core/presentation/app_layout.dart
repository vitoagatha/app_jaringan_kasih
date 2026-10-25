import 'package:flutter/material.dart';

/// Menjaga form/list tetap nyaman dibaca pada layar lebar dan area gesture aman.
class AppContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const AppContent({super.key, required this.child, this.maxWidth = 840});
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth), child: child)),
      );
}

class AppStatusPanel extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  const AppStatusPanel(
      {super.key, required this.title, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Semantics(
              liveRegion: true,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.info_outline, size: 40),
                const SizedBox(height: 16),
                Text(title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                      onPressed: onRetry, child: const Text('Coba lagi'))
                ],
              ])),
        ),
      ));
}

ThemeData appTheme() => ThemeData(
      colorSchemeSeed: Colors.teal,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      inputDecorationTheme:
          const InputDecorationTheme(border: OutlineInputBorder()),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(minimumSize: const Size(48, 48))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48))),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48))),
    );

class UnsupportedPlatformApp extends StatelessWidget {
  const UnsupportedPlatformApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Jaringan Kasih',
      theme: appTheme(),
      home: Scaffold(
          appBar: AppBar(title: const Text('Jaringan Kasih')),
          body: const AppStatusPanel(
              title: 'Gunakan aplikasi Android atau desktop',
              message:
                  'Versi web belum tersedia. Jalankan aplikasi pada Android Emulator atau Windows desktop yang sudah disiapkan.')));
}
