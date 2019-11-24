import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/user_data_container.dart';
import 'package:debtcheck/user_search_delegate.dart';
import 'package:flutter/material.dart';
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
  List<UserData> friendData;
  _FriendsDialogState(this.uid,this.userBloc);
  
  @override
  Widget build(BuildContext context) {
    var container = StateContainer.of(context);
    friendData = userBloc.state.friends;
    return new AlertDialog(
      title: Row(
        children: <Widget>[
          new Text('Friends'),
          new IconButton(
            icon: new Icon(Icons.add),
            onPressed: () async {
              UserData friendUID = await showSearch<UserData>(
                context: context,
                delegate: new UserSearchDelegate(exclude: [container.user.uid, ...friendData.map((user) => user.uid)],),
              );
              if(friendUID != null)
                Firestore.instance.collection('users').document(container.user.uid).updateData({
                  'friends': FieldValue.arrayUnion([friendUID]),
                });
            },
          ),
        ],
      ),
      content: _getContent(),
    );
  }

  Widget _getContent() {
    if(friendData == null)
      return new CircularProgressIndicator();
    else if(friendData.isEmpty)
      return new Text('No friends!');
    else
      return Container(
        width: 200,
        child: new ListView.builder(
          shrinkWrap: true,
          itemCount: friendData.length,
          itemBuilder: (context, index) {
            return new Text(friendData[index].fullName);
          },
        ),
      );
  }

  Future<List<DocumentSnapshot>> _getFriendData(DocumentSnapshot userDoc) async {
    List<Future<DocumentSnapshot>> futures = [];
    var userIds = userDoc.data['friends'];
    userIds.forEach((id) {
      futures.add(Firestore.instance.collection('users').document(id).get());
    });
    List<DocumentSnapshot> docs = await Future.wait(futures);
    return docs;
  }
}