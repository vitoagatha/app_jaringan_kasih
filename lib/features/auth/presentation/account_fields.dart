import 'dart:convert';

import 'package:flutter/material.dart';

import '../application/session_controller.dart';

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  return email.length > 254 ||
          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
      ? 'Masukkan email yang valid.'
      : null;
}

String? validateNewPassword(String? value) {
  final password = value ?? '';
  if (password.runes.length < 8) return 'Password minimal 8 karakter.';
  if (utf8.encode(password).length > 72) return 'Password maksimal 72 byte.';
  return null;
}

class AccountField extends StatelessWidget {
  final SessionController session;
  final TextEditingController controller;
  final String field;
  final String label;
  final bool obscure;
  final bool optional;
  final String? Function(String?)? validator;

  const AccountField(
      {super.key,
      required this.session,
      required this.controller,
      required this.field,
      required this.label,
      this.obscure = false,
      this.optional = false,
      this.validator});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          enabled: !session.busy,
          obscureText: obscure,
          autocorrect: !obscure && field == 'name',
          enableSuggestions: !obscure,
          keyboardType: field == 'email'
              ? TextInputType.emailAddress
              : TextInputType.text,
          onChanged: (_) => session.clearError(),
          decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              errorText: session.error?.errors[field]?.join('\n')),
          validator: validator ??
              (value) => optional || (value?.isNotEmpty ?? false)
                  ? null
                  : '$label wajib diisi.',
        ),
      );
}
