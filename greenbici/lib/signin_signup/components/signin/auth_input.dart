import 'package:flutter/material.dart';

import 'auth_style.dart';

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
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool password;
  final bool email;
  final bool last;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final VoidCallback? onSubmitted;

  @override
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AuthStyle.radius),
      borderSide: const BorderSide(color: AuthStyle.border),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Keep labels readable at large text sizes rather than shrinking them
        // into an outline gap. The field exposes the label to screen readers.
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: const TextStyle(
              color: AuthStyle.accent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: widget.label,
          child: TextField(
            controller: widget.controller,
            textCapitalization: widget.textCapitalization,
            obscureText: widget.password && !_visible,
            autocorrect: !widget.password && !widget.email,
            enableSuggestions: !widget.password,
            autofillHints: widget.autofillHints,
            onSubmitted: widget.onSubmitted == null
                ? null
                : (_) => widget.onSubmitted!(),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            scrollPadding: const EdgeInsets.all(28),
            keyboardType: widget.email
                ? TextInputType.emailAddress
                : widget.password
                ? TextInputType.visiblePassword
                : TextInputType.text,
            textInputAction: widget.last
                ? TextInputAction.done
                : TextInputAction.next,
            cursorColor: AuthStyle.accent,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              color: AuthStyle.foreground,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AuthStyle.field,
              hintText: widget.hint,
              hintStyle: const TextStyle(
                color: AuthStyle.secondary,
                fontSize: 16,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 17,
              ),
              prefixIcon: Icon(
                widget.password
                    ? Icons.lock_outline_rounded
                    : widget.email
                    ? Icons.mail_outline_rounded
                    : Icons.person,
                color: AuthStyle.secondary,
                size: 22,
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
                        color: AuthStyle.secondary,
                      ),
                    )
                  : null,
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: const BorderSide(color: AuthStyle.accent, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
