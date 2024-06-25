import 'package:flutter/material.dart';
import 'package:green/design_system/primitives/custom_typography.dart';
import 'package:provider/provider.dart';

import '../../providers/user_profile_provider.dart';
import '../../screens/userManagement/user_profile.dart';
import 'profile_image_widget.dart';
import 'roles_dropdown.dart';

class ProfileDropdownWidget extends StatelessWidget {
  final bool showOptions;

  ProfileDropdownWidget({required this.showOptions});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showOptions) RolesDropdown(),
        SizedBox(width: 16),
        ProfileMenu(),
      ],
    );
  }
}

class ProfileMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      offset: Offset(0, 50),
      icon: ProfileImageWidget(),
      onSelected: (value) {
        if (value == 1) {
          // Navigate to Edit Profile
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen()),
          );
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(

          value: 1,
          child: Row(
            children: [
              Icon(Icons.edit),
              SizedBox(width: 8),
              Text('Edit Profile', style: CustomTypography.Body1,),
            ],
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Expanded(child: RolesDropdown()),
            ],
          ),
        ),
      ],
    );
  }
}


