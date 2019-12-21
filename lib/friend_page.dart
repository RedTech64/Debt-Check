import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:debtcheck/check_page.dart';
import 'package:debtcheck/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/check_bloc.dart';

class FriendPage extends StatefulWidget {
  final UserData userData;
  FriendPage(this.userData);
  @override
  _FriendPageState createState() => _FriendPageState(this.userData);
}

class _FriendPageState extends State<FriendPage> {
  UserData userData;
  _FriendPageState(this.userData);
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Profile'),),
      body: new Column(
        children: <Widget>[
          new Card(
            child: new Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: new CircularProfileAvatar(
                    userData.profilePicURL,
                    radius: 50,
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
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(8, 8, 8, 2),
                  child: new Text(
                    userData.fullName,
                    style: new TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: new Text(
                    '@${userData.username}',
                  ),
                ),
                new Divider(height: 0,),
                Container(
                  padding: EdgeInsets.all(8),
                  child: new Text(
                    'Friends: ${userData.friendUIDs.length}',
                    style: new TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  child: new Text(
                    'Total Credit: \$${userData.credit.toStringAsFixed(2)}',
                    style: new TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  child: new Text(
                    'Total Debt: \$${userData.debt.toStringAsFixed(2)}',
                    textAlign: TextAlign.left,
                    style: new TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          new RaisedButton(
            child: const Text('View Outstanding Checks'),
            shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0)),
            color: Theme.of(context).primaryColor,
            onPressed: () {
              Navigator.of(context).push(
                new MaterialPageRoute(
                  builder: (BuildContext context) {
                    return new CheckPage('Outstanding Checks', BlocProvider.of<CheckBloc>(context).state.getFromUser(userData.uid));
                  },
                )
              );
            },
          ),
        ],
      ),
    );
  }
}