import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../screens/userManagement/user_profile.dart';

class ProfileImageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfile, child) {
        return CircleAvatar(
          radius: 20.0,
          backgroundColor: Colors.grey.shade200,
          child: (userProfile.userData.displayImageUrl ?? "").isNotEmpty
              ? ClipOval(
            child: Image.network(
              userProfile.userData.displayImageUrl ?? '',
              height: 40.0,
              width: 40.0,
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                );
              },
              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                return FallbackAvatar(name: userProfile.userData?.name ?? 'A');
              },
            ),
          )
              : FallbackAvatar(name: userProfile.userData?.name ?? 'A'),
        );
      },
    );
  }
}

class FallbackAvatar extends StatelessWidget {
  final String name;

  FallbackAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.grey,
      child: Text(
        name.isNotEmpty ? name[0] : '?',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
