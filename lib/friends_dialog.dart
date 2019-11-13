import 'package:cloud_firestore/cloud_firestore.dart' as prefix0;
import 'package:debt_check/user_data_container.dart';
import 'package:flutter/material.dart';
import 'friend_finder.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsDialog extends StatefulWidget {
  String uid;
  FriendsDialog(this.uid);
  @override
  _FriendsDialogState createState() => _FriendsDialogState(this.uid);
}

class _FriendsDialogState extends State<FriendsDialog> {
  String uid;
  List<DocumentSnapshot> friendData;
  StreamController<List<DocumentSnapshot>> _streamController;
  StreamSubscription listener;
  _FriendsDialogState(this.uid);

  @override
  void initState() {
    print("DID CGANGE");
    _streamController = new StreamController<List<DocumentSnapshot>>();

    listener = Firestore.instance.collection('users').document(uid).snapshots().listen((data) async {
      List<DocumentSnapshot> newFriendData = await _getFriendData(data);
      setState(() {
        friendData = newFriendData;
      });
    });
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    var container = StateContainer.of(context);
    return new AlertDialog(
      title: Row(
        children: <Widget>[
          new Text('Friends'),
          new IconButton(
            icon: new Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push(
                new MaterialPageRoute(
                  builder: (BuildContext context) {
                    return new FindFriendsPage(exclude: [container.user.uid, ...friendData.map((doc) => doc.documentID)],);
                  },
                ),
              );
            },
          ),
        ],
      ),
      content: _getContent(),
      /*content: new StreamBuilder<List<DocumentSnapshot>>(
          stream: _streamController.stream,
          builder: (context, snapshot) {
            if(snapshot.connectionState == ConnectionState.waiting || snapshot.data == null)
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new CircularProgressIndicator(),
                ],
              );

          }
      ),*/
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
            return new Text(friendData[index].data['firstName']);
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

  @override
  void dispose() {
    _streamController.close();
    listener.cancel();
    super.dispose();
  }
}