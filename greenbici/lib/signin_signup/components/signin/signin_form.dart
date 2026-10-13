import 'package:flutter/material.dart';

import '../../../navbar/app_shell.dart';

import 'auth_action_button.dart';
import 'auth_input.dart';
import 'auth_style.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});
  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _username = TextEditingController();
  final _password = TextEditingController();

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    final name = _username.text.trim();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AppShell(displayName: name.isEmpty ? 'Alex' : name),
      ),
    );
  }

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
        const SizedBox(height: 20),
        AuthInput(
          label: 'Password',
          hint: 'Password',
          controller: _password,
          password: true,
          last: true,
          autofillHints: const [AutofillHints.password],
          onSubmitted: _submit,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              minimumSize: const Size(48, 48),
              foregroundColor: AuthStyle.accent,
              textStyle: const TextStyle(
                fontFamily: 'Arial',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => showAuthMessage(
              context,
              'Password recovery is not connected yet.',
            ),
            child: const Text('Forgot Password?', textAlign: TextAlign.end),
          ),
        ),
        const SizedBox(height: 16),
        AuthActionButton(label: 'Sign In', onPressed: _submit),
      ],
    ),
  );
}
