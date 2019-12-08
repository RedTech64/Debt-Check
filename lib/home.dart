import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/bloc/user_bloc.dart';
import 'package:debtcheck/check_create_dialog.dart';
import 'package:debtcheck/check_list.dart';
import 'package:debtcheck/friends_dialog.dart';
import 'package:debtcheck/friend_tab.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/check_bloc.dart';

FirebaseAuth _auth = FirebaseAuth.instance;

class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CheckData> checks = [];

  @override
  Widget build(BuildContext context) {
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
              icon: new Icon(Icons.mode_comment),
              onPressed: () {
                BlocProvider.of<CheckBloc>(context).add(StartCheckBloc());
              },
            ),
            new IconButton(
              icon: new Icon(Icons.person),
              onPressed: () => _openFriendsDialog(context),
            ),
            new IconButton(icon: new Icon(Icons.exit_to_app), onPressed: () {_auth.signOut(); BlocProvider.of<UserBloc>(context).add(StartUserBloc(null)); Navigator.pushNamed(context, '/signup');}),],
        ),
        body: TabBarView(
          children: <Widget>[
            new FriendsTab(),
            BlocBuilder<CheckBloc,CheckState>(
              builder: (context, state) {
                return new CheckList(state.received);
              },
            ),
            BlocBuilder<CheckBloc,CheckState>(
              builder: (context, state) {
                return new CheckList(state.sent);
              },
            ),
          ],
        ),
        floatingActionButton: new FloatingActionButton(
          child: new Icon(Icons.send),
          onPressed: () => _openCreateCheckDialog(BlocProvider.of<UserBloc>(context).state.userData),
        ),
      ),
    );
  }

  void _openCreateCheckDialog(UserData userData) async {
    CheckData checkData = await Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (BuildContext context) => new CheckCreateDialog(),
      ),
    );
    if(checkData != null) {
      if(!userData.friendUIDs.contains(checkData.debitorUID)) {
        Firestore.instance.collection('users').document(userData.uid).updateData({
          'friends': FieldValue.arrayUnion([checkData.debitorUID]),
        });
      }
      Firestore.instance.collection('checks').add({
        'description': checkData.description,
        'amount': checkData.amount,
        'date': Timestamp.fromDate(checkData.date),
        'creditorName': userData.fullName,
        'creditorUID': userData.uid,
        'debitorName': checkData.debitorName,
        'debitorUID': checkData.debitorUID,
        'involved': [userData.uid, checkData.debitorUID],
        'paid': false,
      });
    }
  }

  void _openFriendsDialog(context) {
    UserBloc userBloc = BlocProvider.of<UserBloc>(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return new FriendsDialog(BlocProvider.of<UserBloc>(context).state.userData.uid,userBloc);
      }
    );
  }
}

class CheckData {
  String id;
  String description;
  double amount;
  String creditorUID;
  String debitorUID;
  String creditorName;
  String debitorName;
  DateTime date;
  bool paid;

  CheckData({this.id,this.description,this.amount,this.creditorUID,this.debitorUID,this.creditorName,this.debitorName,this.date,this.paid});

  factory CheckData.fromDoc(DocumentSnapshot doc) {
    return new CheckData(id: doc.documentID,description: doc.data['description'], amount: doc.data['amount'], creditorUID: doc.data['creditorUID'], debitorUID: doc.data['debitorUID'], creditorName: doc.data['creditorName'], debitorName: doc.data['debitorName'], date: doc.data['date'].toDate(), paid: doc.data['paid']);
  }
}

class UserData {
  String firstName;
  String lastName;
  String fullName;
  String username;
  String uid;
  List<String> friendUIDs;

  UserData({this.firstName,this.lastName,this.fullName,this.username,this.uid,this.friendUIDs});

  factory UserData.fromDoc(DocumentSnapshot doc) {
    return new UserData(firstName: doc.data['firstName'], lastName: doc.data['lastName'], fullName: doc.data['fullName'], username: doc.data['username'], uid: doc.data['uid'], friendUIDs: new List<String>.from(doc.data['friends']));
  }
}