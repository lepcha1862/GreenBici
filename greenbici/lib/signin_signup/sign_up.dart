import 'package:flutter/material.dart';

import 'components/signin/auth_scene.dart';
import 'components/signin/auth_heading.dart';
import 'components/signin/social_signin_section.dart';
import 'components/signup/signup_form.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) => AuthScene(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(title: 'Join the ride, own the city.'),
        const SizedBox(height: 28),
        const SignUpForm(),
        const SizedBox(height: 24),
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
