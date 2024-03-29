import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:green/design_system/primitives/custom_typography.dart';

import '../../design_system/components/social_media_button.dart';
import '../../design_system/primitives/utilities/custom_spacing.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Create Account Form
            _createAccountForm(),


            // Create Account Button
          ],
        ),
      ),
    );
  }

  _createAccountForm() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text('Create a user account', style: CustomTypography.H5_Regular,textAlign: TextAlign.center,),
          ),
          SizedBox(height: CustomSpacing.eight),
          // Social Media Buttons
          SocialMediaButton(
            onPressed: () {
              // Add your onPressed function here
            },
            buttonText: 'Continue with Google',
            iconPath: 'assets/images/googleLogo.svg',
          ),
          SizedBox(height: CustomSpacing.one,),
          SocialMediaButton(
            onPressed: () {
              // Add your onPressed function here
            },
            buttonText: 'Continue with Microsoft',
            iconPath: 'assets/images/microsoftLogo.svg',
          ),
          SizedBox(height: CustomSpacing.eight),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Colors.white.withOpacity(0.11999999731779099),
                ),
              ),
              SizedBox(width: CustomSpacing.three),
              Text(
                'Or register manually',
                style: CustomTypography.Subtitle1.copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(width: CustomSpacing.three),
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: Colors.white.withOpacity(0.11999999731779099),
                ),
              ),
            ],
          ),
          SizedBox(height: CustomSpacing.eight),
          Container(
            padding: EdgeInsets.all(CustomSpacing.twoPointFive),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Enter name',
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
