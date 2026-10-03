import 'package:flutter/material.dart';

/// Shared transparent field, with the reference's close-set external label.
class AuthInput extends StatelessWidget {
  const AuthInput({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.password = false,
    this.email = false,
    this.last = false,
    this.autofillHints,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool password;
  final bool email;
  final bool last;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label),
      Semantics(
        label: label,
        child: TextField(
          controller: controller,
          obscureText: password,
          autocorrect: !password && !email,
          enableSuggestions: !password,
          autofillHints: autofillHints,
          scrollPadding: const EdgeInsets.all(24),
          keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
          textInputAction: last ? TextInputAction.done : TextInputAction.next,
          style: const TextStyle(fontSize: 20, color: Color(0xFFE2E2E2)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCFCFD3), fontSize: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            isDense: true,
            constraints: const BoxConstraints(minHeight: 48),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF373744)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
          ),
        ),
      ),
    ],
  );
}
