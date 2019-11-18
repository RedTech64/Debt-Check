import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debt_check/check_create_dialog.dart';
import 'package:debt_check/friends_dialog.dart';
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
  List<CheckData> checks = [];

  @override
  Widget build(BuildContext context) {
    var container = StateContainer.of(context);
    return StreamBuilder<DocumentSnapshot>(
      stream: Firestore.instance.collection('users').document(container.user.uid).snapshots(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting || snapshot.data == null)
          return new Container();
        return StreamBuilder<QuerySnapshot>(
          stream: Firestore.instance.collection('checks').where('involved', arrayContains: snapshot.data['uid']).snapshots(),
          builder: (context, checksSnapshot) {
            if(checksSnapshot.connectionState != ConnectionState.waiting) {
              checks = checksSnapshot.data.documents.map((doc) => new CheckData.fromDoc(doc)).toList();
            }
            return new DefaultTabController(
              length: 3,
              child: Scaffold(
                appBar: AppBar(
                  title: Text("Debt Check"),
                  bottom: new TabBar(
                    tabs: <Widget>[
                      Tab(icon: new Icon(Icons.person), text: 'Friends',),
                      Tab(icon: new Icon(Icons.arrow_downward), text: 'Received',),
                      Tab(icon: new Icon(Icons.arrow_upward), text: 'Sent',),
                    ],
                  ),
                  actions: <Widget>[
                    new IconButton(
                      icon: new Icon(Icons.person),
                      onPressed: () => _openFriendsDialog(context),
                    ),
                    new IconButton(icon: new Icon(Icons.exit_to_app), onPressed: () {_auth.signOut(); container.updateUserInfo(uid: null); Navigator.pushNamed(context, '/');}),],
                ),
                body: TabBarView(
                  children: <Widget>[
                    new Text('Not yet implemented'),
                    new ListView.builder(
                      itemCount: checks.where((check) {return (check.debitorUID == snapshot.data['uid']);}).length,
                      itemBuilder: (context, index) {
                        List<CheckData> shown = checks.where((check) {return (check.debitorUID == snapshot.data['uid']);}).toList();
                        return new CheckCard(shown[index]);
                      },
                    ),
                    new ListView.builder(
                      itemCount: checks.where((check) {return (check.creditorUID == snapshot.data['uid']);}).toList().length,
                      itemBuilder: (context, index) {
                        List<CheckData> shown = checks.where((check) {return (check.creditorUID == snapshot.data['uid']);}).toList();
                        return new CheckCard(shown[index]);
                      },
                    ),
                  ],
                ),
                floatingActionButton: new FloatingActionButton(
                  child: new Icon(Icons.send),
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _openFriendsDialog(context) {
    var container = StateContainer.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return new FriendsDialog(container.user.uid);
      }
    );
  }
}

class CheckCard extends StatelessWidget {
  final CheckData checkData;

  CheckCard(this.checkData);

  @override
  Widget build(BuildContext context) {
    var container = StateContainer.of(context);
    return new Card(
      child: new Column(
        children: <Widget>[
          if(checkData.creditorUID == container.user.uid)
            new Text('${checkData.debitorName} owes you ${checkData.amount} for ${checkData.description}'),
          if(checkData.debitorName == container.user.uid)
            new Text('You owe ${checkData.creditorName}, ${checkData.amount} for ${checkData.description}'),
        ],
      ),
    );
  }
}

class CheckData {
  String description;
  double amount;
  String creditorUID;
  String debitorUID;
  String creditorName;
  String debitorName;
  DateTime date;

  CheckData(this.description,this.amount,this.creditorUID,this.debitorUID,this.creditorName,this.debitorName,this.date);

  factory CheckData.fromDoc(DocumentSnapshot doc) {
    return new CheckData(doc.data['description'], doc.data['amount'], doc.data['creditorUID'], doc.data['debitorUID'], doc.data['creditorName'], doc.data['debitorName'], doc.data['date'].toDate());
  }
}

class UserData {
  String firstName;
  String lastName;
  String fullName;
  String username;
  String uid;

  UserData({this.firstName,this.lastName,this.fullName,this.username,this.uid});
}