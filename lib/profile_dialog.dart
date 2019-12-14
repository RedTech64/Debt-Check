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
          new Text(
            userData.fullName,
          ),
        ],
      ),
    );
  }
}