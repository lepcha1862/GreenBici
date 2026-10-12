import 'package:flutter/material.dart';

import '../../../navbar/app_shell.dart';

import 'auth_action_button.dart';
import 'auth_input.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});
  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AutofillGroup(
    child: Column(
      children: [
        AuthInput(
          label: 'User Name',
          hint: 'User Name',
          controller: _username,
          autofillHints: const [AutofillHints.username],
        ),
        const SizedBox(height: 28),
        AuthInput(
          label: 'Password',
          hint: 'Password',
          controller: _password,
          password: true,
          last: true,
          autofillHints: const [AutofillHints.password],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: const Color(0xFF93BC58),
              textStyle: const TextStyle(fontFamily: 'Arial', fontSize: 16),
            ),
            onPressed: () => showAuthMessage(
              context,
              'Password recovery is not connected yet.',
            ),
            child: const Text('Forgot Password?'),
          ),
        ),
        const SizedBox(height: 32),
        AuthActionButton(
          label: 'Sign In',
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            final name = _username.text.trim();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AppShell(displayName: name.isEmpty ? 'Alex' : name),
              ),
            );
          },
        ),
      ],
    ),
  );
}
