import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/user_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'home.dart';
import 'bloc/user_bloc.dart';

class FriendsDialog extends StatefulWidget {
  String uid;
  UserBloc userBloc;
  FriendsDialog(this.uid,this.userBloc);
  @override
  _FriendsDialogState createState() => _FriendsDialogState(this.uid,this.userBloc);
}

class _FriendsDialogState extends State<FriendsDialog> {
  String uid;
  UserBloc userBloc;
  _FriendsDialogState(this.uid,this.userBloc);
  
  @override
  Widget build(BuildContext context) {
    return new BlocBuilder<UserBloc, UserState>(
      builder: (context,state) {
        return new AlertDialog(
          title: Row(
            children: <Widget>[
              new Text('Friends'),
              new IconButton(
                icon: new Icon(Icons.add),
                onPressed: () async {
                  UserData newFriend = await showSearch<UserData>(
                    context: context,
                    delegate: new UserSearchDelegate(exclude: [BlocProvider.of<UserBloc>(context).state.userData.uid, ...state.friends.map((user) => user.uid)],),
                  );
                  if(newFriend != null && state.friends.where((friend) => friend.uid == newFriend.uid).length == 0)
                    Firestore.instance.collection('users').document(BlocProvider.of<UserBloc>(context).state.userData.uid).updateData({
                      'friends': FieldValue.arrayUnion([newFriend.uid]),
                    });
                },
              ),
            ],
          ),
          content: _getContent(state),
        );
      },
    );
  }

  Widget _getContent(UserState state) {
    if(state.friends == null)
      return new CircularProgressIndicator();
    else if(state.friends.isEmpty)
      return new Text('No friends!');
    else
      return Container(
        width: 200,
        child: new ListView.builder(
          shrinkWrap: true,
          itemCount: state.friends.length,
          itemBuilder: (context, index) {
            return new ListTile(
              title: new Text(state.friends[index].fullName),
              subtitle: new Text('@${state.friends[index].username}'),
            );
          },
        ),
      );
  }
}