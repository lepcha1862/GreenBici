import 'package:flutter/material.dart';

import 'components/signin/auth_scene.dart';
import 'components/signin/brand_header.dart';
import 'components/signin/social_signin_section.dart';
import 'components/signup/signup_form.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) => AuthScene(
    topSpacing: 38,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BrandHeader(),
        const SizedBox(height: 37),
        const Text('Join the ride, own the city.', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        const SignUpForm(),
        const SizedBox(height: 16),
        SocialSignInSection(
          accountPrompt: 'Already have an account?',
          linkLabel: 'Sign In',
          onNavigate: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
