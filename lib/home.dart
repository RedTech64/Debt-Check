import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debt_check/user_data_container.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseAuth _auth = FirebaseAuth.instance;

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var container = StateContainer.of(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: Firestore.instance.collection('users').document(container.user.uid).snapshots(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting)
          return new Container();
        return Scaffold(
          appBar: AppBar(
            title: Text("Debt Check"),
            actions: <Widget>[
              new IconButton(
                icon: new Icon(Icons.person),
                onPressed: () => _openFriendsDialog(snapshot,context),
              ),
              new IconButton(icon: new Icon(Icons.exit_to_app), onPressed: () {_auth.signOut(); container.updateUserInfo(uid: null); Navigator.pushNamed(context, '/');}),],
          ),
          body: Column(
            children: <Widget>[
              new Card(
                child: new Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(8),
                      child: new Text("Hello, "+snapshot.data['firstName']),
                      ),
                    ],
                  ),
                ),
              ],
            )
        );
      }
    );
  }

  Future<List<DocumentSnapshot>> _getFriendData(DocumentSnapshot userDoc) async {
    print('run');
    print(userDoc.data['friends']);
    List<Future<DocumentSnapshot>> futures = [];
    var userIds = userDoc.data['friends'];
    print(userIds.toString());
    userIds.forEach((id) {
      futures.add(Firestore.instance.collection('users').document(id).get());
    });
    List<DocumentSnapshot> docs = await Future.wait(futures);
    return docs;
  }

  void _openFriendsDialog(AsyncSnapshot<DocumentSnapshot> userDoc,context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Friends'),
          content: new FutureBuilder<List<DocumentSnapshot>>(
              future: _getFriendData(userDoc.data),
              builder: (context, snapshot) {
                print('test');
                if(snapshot.connectionState == ConnectionState.waiting || snapshot.data == null)
                  return new Text('loading');
                return Container(
                  width: 200,
                  child: new ListView.builder(
                    shrinkWrap: true,
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, index) {
                      return new Text(snapshot.data[index]['firstName']);
                    },
                  ),
                );
              }
          ),
        );
      }
    );
  }
}