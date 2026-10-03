import 'package:flutter/material.dart';

import 'components/signin/auth_scene.dart';
import 'components/signin/brand_header.dart';
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
        const BrandHeader(),
        const SizedBox(height: 25),
        const Text('Sign in, unlock your ride, let the city roll'),
        const SizedBox(height: 16),
        const SignInForm(),
        const SizedBox(height: 22),
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
