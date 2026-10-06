import 'package:flutter/material.dart';

/// Outlined field shared by both authentication screens.
class AuthInput extends StatefulWidget {
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
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: Color(0xFFCBD1D1), width: 1.2),
    );
    return TextField(
      controller: widget.controller,
      obscureText: widget.password && !_visible,
      autocorrect: !widget.password && !widget.email,
      enableSuggestions: !widget.password,
      autofillHints: widget.autofillHints,
      scrollPadding: const EdgeInsets.all(28),
      keyboardType: widget.email
          ? TextInputType.emailAddress
          : TextInputType.text,
      textInputAction: widget.last
          ? TextInputAction.done
          : TextInputAction.next,
      style: const TextStyle(fontSize: 19, color: Color(0xFFF1F2EF)),
      decoration: InputDecoration(
        labelText: widget.label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(color: Color(0xFF93BC58), fontSize: 21),
        hintText: widget.hint,
        hintStyle: const TextStyle(color: Color(0xFFBEC3C4), fontSize: 19),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 25,
        ),
        prefixIcon: Icon(
          widget.password
              ? Icons.lock_outline_rounded
              : widget.email
              ? Icons.mail_outline_rounded
              : Icons.person,
          color: const Color(0xFFE8EEED),
          size: 25,
        ),
        suffixIcon: widget.password
            ? IconButton(
                tooltip: _visible ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => _visible = !_visible),
                icon: Icon(
                  _visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 22,
                  color: const Color(0xFFE8EEED),
                ),
              )
            : null,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFF93BC58), width: 1.8),
        ),
      ),
    );
  }
}
