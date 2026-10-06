import 'package:flutter/material.dart';

import 'components/signin/auth_scene.dart';
import 'components/signin/brand_header.dart';
import 'components/signin/social_signin_section.dart';
import 'components/signup/signup_form.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) => AuthScene(
    topSpacing: 72,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BrandHeader(),
        const SizedBox(height: 37),
        const Text(
          'Join the ride, own the city.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 23, height: 1.5),
        ),
        const SizedBox(height: 30),
        const SignUpForm(),
        const SizedBox(height: 30),
        SocialSignInSection(
          signUp: true,
          accountPrompt: 'Already have an account?',
          linkLabel: 'Sign In',
          onNavigate: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
