import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/bloc/user_bloc.dart';
import 'package:debtcheck/check_create_dialog.dart';
import 'package:debtcheck/check_list.dart';
import 'package:debtcheck/friend_tab.dart';
import 'package:debtcheck/profile_dialog.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
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
    return new BlocBuilder<UserBloc,UserState>(
      builder: (context, state) {
        return new DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text("Debt Check"),
              bottom: new TabBar(
                tabs: <Widget>[
                  Tab(icon: new Icon(Icons.person), text: 'Friends',),
                  Tab(icon: new Icon(Icons.arrow_upward), text: 'Sent',),
                  Tab(icon: new Icon(Icons.arrow_downward), text: 'Received',),
                ],
              ),
              actions: <Widget>[
                new IconButton(
                  icon: new Icon(Icons.person),
                  onPressed: () => _openProfileDialog(context),
                ),
                new IconButton(
                  icon: new Icon(Icons.exit_to_app),
                  onPressed: () {
                    _auth.signOut();
                    BlocProvider.of<UserBloc>(context).close();
                    DynamicTheme.of(context).setThemeData(
                      new ThemeData(
                        primarySwatch: Colors.green,
                      ),
                    );
                    Navigator.pushNamed(context, '/signup');
                  }),
              ],
            ),
            body: TabBarView(
              children: <Widget>[
                new FriendsTab(),
                BlocBuilder<CheckBloc,CheckState>(
                  builder: (context, state) {
                    return new CheckList(state.sent);
                  },
                ),
                BlocBuilder<CheckBloc,CheckState>(
                  builder: (context, state) {
                    return new CheckList(state.received);
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
      },
    );
  }

  void _openCreateCheckDialog(UserData userData) async {
    List<CheckData> checks = await Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (BuildContext context) => new CheckCreateDialog(),
      ),
    );
    if(checks != null) {
      for(CheckData checkData in checks) {
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
  }

  void _openProfileDialog(context) {
    UserBloc userBloc = BlocProvider.of<UserBloc>(context);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new ProfileDialog(userBloc.state.userData);
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
  double credit;
  double debt;
  String profilePicURL;

  UserData({this.firstName,this.lastName,this.fullName,this.username,this.uid,this.friendUIDs,this.credit,this.debt,this.profilePicURL});

  factory UserData.fromDoc(DocumentSnapshot doc) {
    return new UserData(firstName: doc.data['firstName'], lastName: doc.data['lastName'], fullName: doc.data['fullName'], username: doc.data['username'], uid: doc.data['uid'], friendUIDs: new List<String>.from(doc.data['friends'],), credit: doc.data['credit'].toDouble(), debt: doc.data['debt'].toDouble(), profilePicURL: doc.data['profilePicURL']);
  }
}