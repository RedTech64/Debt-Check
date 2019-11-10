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
    return Scaffold(
      appBar: AppBar(
        title: Text("Debt Check"),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.exit_to_app), onPressed: () {_auth.signOut(); container.updateUserInfo(uid: null); Navigator.pushNamed(context, '/');}),        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: Firestore.instance.collection('users').document(container.user.uid).snapshots(),
        builder: (context, snapshot) {
          return Column(
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
          );
        }
      ),
    );
  }
}