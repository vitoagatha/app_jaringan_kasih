import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../application/session_controller.dart';
import '../../profile/data/photo_selection.dart';
import '../../profile/presentation/account_home.dart';
import 'password_reset_form.dart';

class JaringanKasihApp extends StatefulWidget {
  final SessionController session;
  final PhotoPicker? photoPicker;

  const JaringanKasihApp({super.key, required this.session, this.photoPicker});

  @override
  State<JaringanKasihApp> createState() => _JaringanKasihAppState();
}

class _JaringanKasihAppState extends State<JaringanKasihApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.session.restore());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !widget.session.externalInteraction &&
        (widget.session.phase == SessionPhase.signedIn ||
            widget.session.phase == SessionPhase.unavailable)) {
      unawaited(widget.session.restore());
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
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: AnimatedBuilder(
          animation: widget.session,
          builder: (context, _) {
            final session = widget.session;
            switch (session.phase) {
              case SessionPhase.restoring:
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              case SessionPhase.unavailable:
                return Scaffold(
                  appBar: AppBar(title: const Text('Jaringan Kasih')),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('Sesi belum dapat diperiksa.'),
                        const SizedBox(height: 12),
                        Text(session.error!.message,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                            onPressed: session.restore,
                            child: const Text('Coba lagi')),
                      ]),
                    ),
                  ),
                );
              case SessionPhase.signedOut:
                return _AuthForm(session: session);
              case SessionPhase.signedIn:
                return AccountHome(
                    session: session, photoPicker: widget.photoPicker);
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
      appBar: AppBar(title: const Text('Jaringan Kasih')),
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
                      style: Theme.of(context).textTheme.headlineMedium),
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
                      child: Text(session.error!.message,
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
