import 'package:flutter/material.dart';

import '../../auth/application/session_controller.dart';
import '../../auth/presentation/account_fields.dart';
import '../data/photo_selection.dart';
import 'profile_photo_editor.dart';
import '../../../core/presentation/app_layout.dart';

class AccountHome extends StatefulWidget {
  final SessionController session;
  final PhotoPicker? photoPicker;
  final VoidCallback? onExplore;
  final VoidCallback? onMyFundings;
  final VoidCallback? onWishlist;

  const AccountHome(
      {super.key,
      required this.session,
      this.photoPicker,
      this.onExplore,
      this.onMyFundings,
      this.onWishlist});

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

  Widget _menuTile({
    required Key key,
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
    String? subtitle,
    Widget? trailing,
    Color? foregroundColor,
  }) =>
      ListTile(
        key: key,
        leading: Icon(icon, color: foregroundColor),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final name = session.user!.name.trim();
    final initial = name.isEmpty
        ? '?'
        : String.fromCharCode(name.runes.first).toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Akun saya')),
      body: AppContent(
          child: ListView(padding: const EdgeInsets.all(24), children: [
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CircleAvatar(radius: 26, child: Text(initial)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Halo, ${session.user!.name}',
                            key: const Key('account_greeting'),
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(session.user!.email,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(session.user!.emailVerified
                            ? 'Email terverifikasi'
                            : 'Email belum terverifikasi'),
                      ])),
                  const Icon(Icons.settings_outlined),
                ]))),
        if (_message != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_message!)),
        if (session.error != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(session.error!.displayMessage,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 20),
        Text('Pengaturan akun', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: ProfilePhotoEditor(
                      session: session, picker: widget.photoPicker)),
              const Divider(height: 1, indent: 56),
              _menuTile(
                key: const Key('edit_profile'),
                icon: Icons.person_outline,
                title: _editing ? 'Batal edit profil' : 'Edit profil',
                trailing:
                    Icon(_editing ? Icons.expand_less : Icons.chevron_right),
                onTap: session.busy
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
              ),
              if (_editing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Form(
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
                ),
              const Divider(height: 1, indent: 56),
              _menuTile(
                key: const Key('change_password'),
                icon: Icons.lock_outline,
                title:
                    _changingPassword ? 'Batal ubah password' : 'Ubah password',
                trailing: Icon(_changingPassword
                    ? Icons.expand_less
                    : Icons.chevron_right),
                onTap: session.busy
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
              ),
              if (_changingPassword)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Form(
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
                ),
              if (!session.user!.emailVerified) ...[
                const Divider(height: 1, indent: 56),
                _menuTile(
                    key: const Key('verify_email'),
                    icon: Icons.mark_email_unread_outlined,
                    title: 'Kirim verifikasi email',
                    subtitle: 'Email belum terverifikasi',
                    onTap: session.busy ? null : _verify),
              ],
              const Divider(height: 1, indent: 56),
              _menuTile(
                  key: const Key('account_check_session'),
                  icon: Icons.sync,
                  title: 'Periksa sesi',
                  onTap: session.busy ? null : session.restore),
            ])),
        if (widget.onExplore != null ||
            widget.onMyFundings != null ||
            widget.onWishlist != null) ...[
          const SizedBox(height: 20),
          Text('Aktivitas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                if (widget.onExplore != null)
                  _menuTile(
                      key: const Key('account_explore_fundings'),
                      icon: Icons.search,
                      title: 'Jelajahi pendanaan',
                      onTap: widget.onExplore),
                if (widget.onMyFundings != null) ...[
                  if (widget.onExplore != null)
                    const Divider(height: 1, indent: 56),
                  _menuTile(
                      key: const Key('account_my_fundings'),
                      icon: Icons.volunteer_activism_outlined,
                      title: 'Pendanaan saya',
                      onTap: widget.onMyFundings),
                ],
                if (widget.onWishlist != null) ...[
                  if (widget.onExplore != null || widget.onMyFundings != null)
                    const Divider(height: 1, indent: 56),
                  _menuTile(
                      key: const Key('account_wishlist'),
                      icon: Icons.favorite_border,
                      title: 'Wishlist',
                      onTap: widget.onWishlist),
                ],
              ])),
        ],
        const SizedBox(height: 20),
        Card(
            clipBehavior: Clip.antiAlias,
            child: _menuTile(
                key: const Key('auth_logout'),
                icon: Icons.logout,
                title: session.busy ? 'Memproses...' : 'Keluar',
                foregroundColor: Theme.of(context).colorScheme.error,
                trailing: const Icon(Icons.chevron_right),
                onTap: session.busy ? null : session.logout)),
      ])),
    );
  }
}
