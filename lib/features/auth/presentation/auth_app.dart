import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../application/session_controller.dart';
import '../../profile/data/photo_selection.dart';
import '../data/onboarding_store.dart';
import 'password_reset_form.dart';
import 'signed_in_shell.dart';
import 'welcome_screens.dart';
import '../../../core/presentation/app_layout.dart';

class JaringanKasihApp extends StatefulWidget {
  final SessionController session;
  final PhotoPicker? photoPicker;
  final OnboardingStore? onboardingStore;

  const JaringanKasihApp(
      {super.key,
      required this.session,
      this.photoPicker,
      this.onboardingStore});

  @override
  State<JaringanKasihApp> createState() => _JaringanKasihAppState();
}

class _JaringanKasihAppState extends State<JaringanKasihApp>
    with WidgetsBindingObserver {
  bool _onboardingReady = false;
  bool _showOnboarding = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.session.restore());
    if (widget.onboardingStore == null) {
      _onboardingReady = true;
    } else {
      unawaited(_loadOnboarding());
    }
  }

  Future<void> _loadOnboarding() async {
    try {
      _showOnboarding = !await widget.onboardingStore!.hasCompleted();
    } catch (_) {
      // Jangan anggap panduan sudah selesai jika statusnya gagal dibaca.
      _showOnboarding = true;
    } finally {
      if (mounted) setState(() => _onboardingReady = true);
    }
  }

  Future<void> _finishOnboarding() async {
    try {
      await widget.onboardingStore?.complete();
    } catch (_) {
      // Tetap izinkan pengguna masuk jika penyimpanan preferensi tidak tersedia.
    }
    if (mounted) setState(() => _showOnboarding = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !widget.session.externalInteraction &&
        (widget.session.phase == SessionPhase.signedIn ||
            widget.session.phase == SessionPhase.unavailable)) {
      unawaited(widget.session.restore(keepView: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Jaringan Kasih',
        theme: appTheme(),
        home: AnimatedBuilder(
          animation: widget.session,
          builder: (context, _) {
            final session = widget.session;
            if (!_onboardingReady || session.phase == SessionPhase.restoring) {
              return const StartupSplash();
            }
            if (_showOnboarding) {
              return WelcomeOnboarding(
                  onContinue: () => unawaited(_finishOnboarding()));
            }
            switch (session.phase) {
              case SessionPhase.restoring:
                return const StartupSplash();
              case SessionPhase.unavailable:
                return Scaffold(
                  appBar: AppBar(title: const Text('Jaringan Kasih')),
                  body: AppStatusPanel(
                      title: 'Sesi belum dapat diperiksa.',
                      message: session.error!.displayMessage,
                      onRetry: session.restore),
                );
              case SessionPhase.signedOut:
                return _AuthForm(session: session);
              case SessionPhase.signedIn:
                final Widget page = SignedInShell(
                    key: ValueKey(session.user!.id),
                    session: session,
                    photoPicker: widget.photoPicker);
                return Stack(children: [
                  AbsorbPointer(absorbing: session.busy, child: page),
                  if (session.busy)
                    const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                            semanticsLabel: 'Memproses permintaan')),
                ]);
            }
          },
        ),
      );
}

class _AuthForm extends StatefulWidget {
  final SessionController session;

  const _AuthForm({required this.session});

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _register = false;
  bool _showPassword = false;
  bool _resetPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.session.busy) return;
    FocusScope.of(context).unfocus();
    widget.session.clearError();
    if (!_form.currentState!.validate()) return;
    if (_register) {
      await widget.session.register(
          _name.text, _email.text, _password.text, _confirmation.text);
    } else {
      await widget.session.login(_email.text, _password.text);
    }
  }

  InputDecoration _decoration(String label, String field) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: widget.session.error?.errors[field]?.join('\n'),
      );

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    if (_resetPassword) {
      return PasswordResetForm(
          session: session,
          initialEmail: _email.text,
          onBack: () {
            session.clearError();
            setState(() => _resetPassword = false);
          });
    }
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_register ? 'Buat akun' : 'Masuk',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(
                              fontSize: 36, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    _register
                        ? 'Bergabung untuk menemukan dan membuat pendanaan.'
                        : 'Masuk untuk melanjutkan kebaikan bersama.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_register) ...[
                    TextFormField(
                      key: const Key('auth_name'),
                      controller: _name,
                      enabled: !session.busy,
                      textCapitalization: TextCapitalization.words,
                      decoration: _decoration('Nama', 'name'),
                      onChanged: (_) => session.clearError(),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Nama wajib diisi.'
                              : value.trim().runes.length > 100
                                  ? 'Nama maksimal 100 karakter.'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    key: const Key('auth_email'),
                    controller: _email,
                    enabled: !session.busy,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: _decoration('Email', 'email'),
                    onChanged: (_) => session.clearError(),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Email wajib diisi.';
                      if (email.length > 254 ||
                          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(email)) {
                        return 'Format email tidak valid.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('auth_password'),
                    controller: _password,
                    enabled: !session.busy,
                    obscureText: !_showPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: _decoration('Password', 'password').copyWith(
                      suffixIcon: IconButton(
                        tooltip: _showPassword
                            ? 'Sembunyikan password'
                            : 'Tampilkan password',
                        onPressed: session.busy
                            ? null
                            : () =>
                                setState(() => _showPassword = !_showPassword),
                        icon: Icon(_showPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                    onChanged: (_) => session.clearError(),
                    validator: (value) {
                      final password = value ?? '';
                      if (password.isEmpty) return 'Password wajib diisi.';
                      if (_register && password.runes.length < 8) {
                        return 'Password minimal 8 karakter.';
                      }
                      if (utf8.encode(password).length > 72) {
                        return 'Password maksimal 72 byte.';
                      }
                      return null;
                    },
                    onFieldSubmitted: _register ? null : (_) => _submit(),
                  ),
                  if (_register) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('auth_confirmation'),
                      controller: _confirmation,
                      enabled: !session.busy,
                      obscureText: !_showPassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: _decoration(
                          'Konfirmasi password', 'password_confirmation'),
                      onChanged: (_) => session.clearError(),
                      validator: (value) => value != _password.text
                          ? 'Konfirmasi password tidak cocok.'
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ],
                  if (session.error != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(session.error!.displayMessage,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('auth_submit'),
                    onPressed: session.busy ? null : _submit,
                    child: session.busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_register ? 'Daftar' : 'Masuk'),
                  ),
                  if (!_register)
                    TextButton(
                      key: const Key('forgot_password'),
                      onPressed: session.busy
                          ? null
                          : () {
                              session.clearError();
                              _password.clear();
                              setState(() => _resetPassword = true);
                            },
                      child: const Text('Lupa password?'),
                    ),
                  TextButton(
                    key: const Key('auth_toggle'),
                    onPressed: session.busy
                        ? null
                        : () {
                            session.clearError();
                            _form.currentState!.reset();
                            _password.clear();
                            _confirmation.clear();
                            setState(() {
                              _register = !_register;
                              _showPassword = false;
                            });
                          },
                    child: Text(_register
                        ? 'Sudah punya akun? Masuk'
                        : 'Belum punya akun? Daftar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
