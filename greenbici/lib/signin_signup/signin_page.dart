import 'package:flutter/material.dart';

import 'components/signin/auth_scene.dart';
import 'components/signin/auth_heading.dart';
import 'components/signin/signin_form.dart';
import 'components/signin/social_signin_section.dart';
import 'sign_up.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) => AuthScene(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(
          title: 'Sign in, unlock your ride,\nlet the city roll.',
        ),
        const SizedBox(height: 28),
        const SignInForm(),
        const SizedBox(height: 24),
        SocialSignInSection(
          accountPrompt: 'Don’t have an account?',
          linkLabel: 'Sign Up',
          onNavigate: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const SignUpPage())),
        ),
      ],
    ),
  );
}
