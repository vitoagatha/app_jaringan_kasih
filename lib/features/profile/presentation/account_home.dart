import 'package:flutter/material.dart';

import '../../auth/application/session_controller.dart';
import '../../auth/presentation/account_fields.dart';
import '../data/photo_selection.dart';
import 'profile_photo_editor.dart';

class AccountHome extends StatefulWidget {
  final SessionController session;
  final PhotoPicker? photoPicker;

  const AccountHome({super.key, required this.session, this.photoPicker});

  @override
  State<AccountHome> createState() => _AccountHomeState();
}

class _AccountHomeState extends State<AccountHome> {
  final _profileForm = GlobalKey<FormState>();
  final _passwordForm = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _emailPassword = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmation = TextEditingController();
  bool _editing = false;
  bool _changingPassword = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _name.text = widget.session.user!.name;
    _email.text = widget.session.user!.email;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _emailPassword.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    widget.session.clearError();
    if (!_profileForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = await widget.session
        .updateProfile(_name.text, _email.text, _emailPassword.text);
    if (!mounted || !success) return;
    setState(() {
      _editing = false;
      _emailPassword.clear();
      _message = 'Profil disimpan.';
    });
  }

  Future<void> _savePassword() async {
    widget.session.clearError();
    if (!_passwordForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await widget.session.changePassword(
        _currentPassword.text, _newPassword.text, _confirmation.text);
  }

  Future<void> _verify() async {
    if (await widget.session.sendVerification() && mounted) {
      setState(() => _message =
          'Tautan verifikasi dikirim. Buka email, lalu kembali dan tekan Periksa sesi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      appBar: AppBar(title: const Text('Jaringan Kasih')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Text('Halo, ${session.user!.name}',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(session.user!.email),
        Text(session.user!.emailVerified
            ? 'Email terverifikasi'
            : 'Email belum terverifikasi'),
        if (!session.user!.emailVerified)
          OutlinedButton(
              key: const Key('verify_email'),
              onPressed: session.busy ? null : _verify,
              child: const Text('Kirim verifikasi email')),
        if (_message != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_message!)),
        if (session.error != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(session.error!.message,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        const Divider(height: 32),
        ProfilePhotoEditor(session: session, picker: widget.photoPicker),
        const Divider(height: 32),
        OutlinedButton(
            key: const Key('edit_profile'),
            onPressed: session.busy
                ? null
                : () {
                    session.clearError();
                    setState(() {
                      _editing = !_editing;
                      _name.text = session.user!.name;
                      _email.text = session.user!.email;
                      _emailPassword.clear();
                    });
                  },
            child: Text(_editing ? 'Batal edit profil' : 'Edit profil')),
        if (_editing)
          Form(
              key: _profileForm,
              child: Column(children: [
                AccountField(
                    key: const Key('profile_name'),
                    session: session,
                    controller: _name,
                    field: 'name',
                    label: 'Nama',
                    validator: (value) => value == null ||
                            value.trim().isEmpty ||
                            value.trim().runes.length > 100
                        ? 'Nama wajib diisi, maksimal 100 karakter.'
                        : null),
                AccountField(
                    session: session,
                    controller: _email,
                    field: 'email',
                    label: 'Email',
                    validator: validateEmail),
                AccountField(
                    session: session,
                    controller: _emailPassword,
                    field: 'current_password',
                    label: 'Password saat ini (jika mengganti email)',
                    obscure: true,
                    optional: true),
                FilledButton(
                    key: const Key('profile_save'),
                    onPressed: session.busy ? null : _saveProfile,
                    child: const Text('Simpan profil')),
              ])),
        OutlinedButton(
            key: const Key('change_password'),
            onPressed: session.busy
                ? null
                : () {
                    session.clearError();
                    setState(() {
                      _changingPassword = !_changingPassword;
                      _currentPassword.clear();
                      _newPassword.clear();
                      _confirmation.clear();
                    });
                  },
            child: Text(
                _changingPassword ? 'Batal ubah password' : 'Ubah password')),
        if (_changingPassword)
          Form(
              key: _passwordForm,
              child: Column(children: [
                const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                        'Semua sesi akan dikeluarkan setelah password diubah.')),
                AccountField(
                    session: session,
                    controller: _currentPassword,
                    field: 'current_password',
                    label: 'Password saat ini',
                    obscure: true),
                AccountField(
                    session: session,
                    controller: _newPassword,
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
                    validator: (value) => value == _newPassword.text
                        ? null
                        : 'Konfirmasi password tidak cocok.'),
                FilledButton(
                    key: const Key('password_save'),
                    onPressed: session.busy ? null : _savePassword,
                    child: const Text('Simpan password baru')),
              ])),
        const SizedBox(height: 24),
        OutlinedButton(
            onPressed: session.busy ? null : session.restore,
            child: const Text('Periksa sesi')),
        FilledButton(
            key: const Key('auth_logout'),
            onPressed: session.busy ? null : session.logout,
            child: Text(session.busy ? 'Memproses...' : 'Keluar')),
      ]),
    );
  }
}
