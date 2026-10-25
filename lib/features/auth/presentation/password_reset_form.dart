import 'package:flutter/material.dart';

import '../application/session_controller.dart';
import 'account_fields.dart';

class PasswordResetForm extends StatefulWidget {
  final SessionController session;
  final String initialEmail;
  final VoidCallback onBack;

  const PasswordResetForm(
      {super.key,
      required this.session,
      required this.initialEmail,
      required this.onBack});

  @override
  State<PasswordResetForm> createState() => _PasswordResetFormState();
}

class _PasswordResetFormState extends State<PasswordResetForm> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _reset = false;
  bool _done = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    widget.session.clearError();
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final resetting = _reset;
    final success = resetting
        ? await widget.session.resetPassword(
            _email.text, _token.text, _password.text, _confirmation.text)
        : await widget.session.forgotPassword(_email.text);
    if (!mounted || !success) return;
    setState(() {
      _message = resetting
          ? 'Password direset. Silakan login dengan password baru.'
          : 'Jika email terdaftar, petunjuk reset telah dikirim. Salin token dari email.';
      _done = resetting;
      _reset = true;
      _password.clear();
      _confirmation.clear();
      if (resetting) _token.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      appBar: AppBar(title: const Text('Pemulihan akun')),
      body: Center(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_reset ? 'Atur password baru' : 'Lupa password',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  if (_message != null)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(_message!)),
                  if (!_done) ...[
                    AccountField(
                        key: const Key('reset_email'),
                        session: session,
                        controller: _email,
                        field: 'email',
                        label: 'Email',
                        validator: validateEmail),
                    if (_reset) ...[
                      AccountField(
                          key: const Key('reset_token'),
                          session: session,
                          controller: _token,
                          field: 'token',
                          label: 'Token dari email',
                          validator: (value) => value?.trim().length == 64
                              ? null
                              : 'Salin seluruh token 64 karakter dari email.'),
                      AccountField(
                          key: const Key('reset_password'),
                          session: session,
                          controller: _password,
                          field: 'password',
                          label: 'Password baru',
                          obscure: true,
                          validator: validateNewPassword),
                      AccountField(
                          session: session,
                          controller: _confirmation,
                          field: 'password_confirmation',
                          label: 'Konfirmasi password',
                          obscure: true,
                          validator: (value) => value == _password.text
                              ? null
                              : 'Konfirmasi password tidak cocok.'),
                    ],
                    if (session.error != null)
                      Text(session.error!.displayMessage,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    FilledButton(
                        key: const Key('reset_submit'),
                        onPressed: session.busy ? null : _submit,
                        child: Text(session.busy
                            ? 'Memproses...'
                            : _reset
                                ? 'Simpan password baru'
                                : 'Kirim petunjuk reset')),
                    TextButton(
                        onPressed: session.busy
                            ? null
                            : () {
                                session.clearError();
                                _form.currentState!.reset();
                                setState(() {
                                  _reset = !_reset;
                                  _message = null;
                                });
                              },
                        child: Text(_reset
                            ? 'Kirim ulang petunjuk'
                            : 'Sudah punya token? Atur password baru')),
                  ],
                  TextButton(
                      onPressed: session.busy ? null : widget.onBack,
                      child: const Text('Kembali ke login')),
                ],
              )),
        ),
      )),
    );
  }
}
