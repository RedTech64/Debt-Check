import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:flutter/material.dart';

import 'home.dart';

class ProfileDialog extends StatefulWidget {
  final UserData userData;
  ProfileDialog(this.userData);
  @override
  _ProfileDialogState createState() => _ProfileDialogState(this.userData);
}

class _ProfileDialogState extends State<ProfileDialog> {
  UserData userData;
  _ProfileDialogState(this.userData);

  @override
  Widget build(BuildContext context) {
    return new AlertDialog(
      title: new Text('Profile'),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new CircularProfileAvatar(
            userData.profilePicURL,
            radius: 40,
            initialsText: new Text(
              userData.firstName.substring(0,1)+userData.lastName.substring(0,1),
              style: new TextStyle(
                fontSize: 36,
              ),
            ),
            cacheImage: true,
            borderWidth: 0.1,
            backgroundColor: Colors.grey[200],
            borderColor: Colors.black,
          ),
          Container(height: 8,),
          new Text(
            userData.fullName,
          ),
          new Text(
            '@${userData.username}',
          ),
        ],
      ),
    );
  }
}