import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/bloc/check_bloc.dart';
import 'package:debtcheck/check_list.dart';
import 'package:debtcheck/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/user_bloc.dart';
import 'bloc/check_bloc.dart';
import 'friend_page.dart';
import 'user_search_delegate.dart';

class FriendsTab extends StatefulWidget {
  @override
  _FriendsTabState createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc,UserState>(
      builder: (context, userBlocState) {
        return BlocBuilder<CheckBloc,CheckState>(
          builder: (context, checkBlocState) {
            return new SingleChildScrollView(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  ...userBlocState.friends.map((friend) => new FriendCard(friend,checkBlocState.getDebtTo(friend.uid),checkBlocState.getDebtFrom(friend.uid),checkBlocState.getFromUser(friend.uid).length)),
                  new FlatButton(
                    child: new Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new Icon(Icons.add),
                        new Text(' ADD FRIEND'),
                      ],
                    ),
                    onPressed: () async {
                      UserData newFriend = await showSearch<UserData>(
                        context: context,
                        delegate: new UserSearchDelegate(exclude: [BlocProvider.of<UserBloc>(context).state.userData.uid, ...userBlocState.friends.map((user) => user.uid)],),
                      );
                      if(newFriend != null && userBlocState.friends.where((friend) => friend.uid == newFriend.uid).length == 0)
                        Firestore.instance.collection('users').document(BlocProvider.of<UserBloc>(context).state.userData.uid).updateData({
                          'friends': FieldValue.arrayUnion([newFriend.uid]),
                        });
                    },
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }
}

class FriendCard extends StatelessWidget {
  final UserData userData;
  final num sent;
  final num received;
  final int checkNum;
  FriendCard(this.userData,this.sent,this.received,this.checkNum);

  @override
  Widget build(BuildContext context) {
    Color balanceColor;
    if(sent-received >= 0)
      balanceColor = Colors.green;
    else
      balanceColor = Colors.red;
    return new Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            new MaterialPageRoute(
              builder: (BuildContext context) {
                return new FriendPage(userData);
              },
            ),
          );
        },
        child: Container(
          padding: new EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              new ListTile(
                leading: new CircularProfileAvatar(
                  userData.profilePicURL,
                  radius: 20,
                  initialsText: new Text(
                    userData.firstName.substring(0,1)+userData.lastName.substring(0,1),
                    style: new TextStyle(
                    ),
                  ),
                  cacheImage: true,
                  borderWidth: 0.1,
                  backgroundColor: Colors.grey[200],
                  borderColor: Colors.black,
                ),
                title: new Text(
                  userData.fullName,
                  style: new TextStyle(
                    fontSize: 20.0,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Text(
                      '@'+userData.username,
                      style: new TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                    Container(height: 4,),
                    Row(
                      children: <Widget>[
                        new Icon(Icons.arrow_upward, size: 16, color: Colors.grey,),
                        new Text(
                          "\$${sent.toStringAsFixed(2)}",
                          style: new TextStyle(
                            fontSize: 14.0,
                          ),
                        ),
                        Container(width: 12,),
                        new Icon(Icons.arrow_downward, size: 16, color: Colors.grey,),
                        new Text(
                          "\$${received.toStringAsFixed(2)}",
                          style: new TextStyle(
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Column(
                  children: <Widget>[
                    new Text(
                      "\$${(sent-received).toStringAsFixed(2)}",
                      style: new TextStyle(
                        fontSize: 20.0,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                isThreeLine: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}