import 'package:flutter/material.dart';

import '../signin/auth_action_button.dart';
import '../signin/auth_input.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});
  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    for (final controller in [_username, _email, _password, _confirmation]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    String message;
    if ([
      _username,
      _email,
      _password,
      _confirmation,
    ].any((c) => c.text.trim().isEmpty)) {
      message = 'Complete all four fields.';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
        .hasMatch(_email.text.trim())) {
      message = 'Enter a valid email address.';
    } else if (_password.text != _confirmation.text) {
      message = 'Your passwords do not match.';
    } else {
      message = 'Sign-up is not connected to an authentication service yet.';
    }
    showAuthMessage(context, message);
  }

  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: Column(
      children: [
        AuthInput(
          label: 'Full Name',
          hint: 'Enter your full name',
          controller: _username,
          autofillHints: const [AutofillHints.name],
        ),
        const SizedBox(height: 24),
        AuthInput(
          label: 'Email',
          hint: 'Enter your email',
          controller: _email,
          email: true,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 24),
        AuthInput(
          label: 'Password',
          hint: 'Enter your password',
          controller: _password,
          password: true,
          autofillHints: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: 24),
        AuthInput(
          label: 'Confirm Password',
          hint: 'Confirm your password',
          controller: _confirmation,
          password: true,
          last: true,
          autofillHints: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: 30),
        AuthActionButton(label: 'Sign Up', onPressed: _submit),
      ],
    ),
  );
}
