import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/bloc/user_bloc.dart';
import 'package:debtcheck/check_create_dialog.dart';
import 'package:debtcheck/check_list.dart';
import 'package:debtcheck/friend_tab.dart';
import 'package:debtcheck/profile_dialog.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/check_bloc.dart';

class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CheckData> checks = [];

  @override
  Widget build(BuildContext context) {
    Icon brightnessIcon;
    if(DynamicTheme.of(context).brightness == Brightness.light)
      brightnessIcon = new Icon(Icons.brightness_high);
    else
      brightnessIcon = new Icon(Icons.brightness_low);
    return new BlocBuilder<UserBloc,UserState>(
      builder: (context, state) {
        return new DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text('Debt Check'),
              bottom: new TabBar(
                tabs: <Widget>[
                  Tab(icon: new Icon(Icons.person), text: 'Friends',),
                  Tab(icon: new Icon(Icons.arrow_upward), text: 'Sent',),
                  Tab(icon: new Icon(Icons.arrow_downward), text: 'Received',),
                ],
              ),
              actions: <Widget>[
                new IconButton(
                  icon: brightnessIcon,
                  onPressed: () {
                    if(DynamicTheme.of(context).brightness == Brightness.light) {
                      DynamicTheme.of(context).setBrightness(Brightness.dark);
                    } else {
                      DynamicTheme.of(context).setBrightness(Brightness.light);
                    }
                  },
                ),
                new GestureDetector(
                  child: new IconButton(
                    icon: new Icon(Icons.person),
                    onPressed: () => _openProfileDialog(context),
                  ),
                  onLongPress: () => _openDebtKingMenu(context),
                ),
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
        builder: (BuildContext context) => new CheckCreateDialog(BlocProvider.of<UserBloc>(context).state.friends.toList()),
      ),
    );
    if(checks != null) {
      for(CheckData checkData in checks) {
        BlocProvider.of<CheckBloc>(context).add(new CreateCheck(checkData));
      }
    }
  }

  void _openProfileDialog(context) {
    UserState userState = BlocProvider.of<UserBloc>(context).state;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new ProfileDialog(userState.userData);
        }
    );
  }

  void _openDebtKingMenu(context) async {
   QuerySnapshot docs= await Firestore.instance.collection('users').orderBy('debt', descending: true).limit(1).getDocuments();
   UserData king = new UserData.fromDoc(docs.documents[0]);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: new Text('Debt King'),
            content: new Text('The Debt King is: ${king.fullName}, with \$${king.debt} in debt!'),
          );
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
  DateTime lastNudge;

  CheckData({this.id,this.description,this.amount,this.creditorUID,this.debitorUID,this.creditorName,this.debitorName,this.date,this.paid,this.lastNudge});

  factory CheckData.fromDoc(DocumentSnapshot doc) {
    DateTime lastNudge;
    if(doc.data['lastNudge'] == null)
      lastNudge = null;
    else
      lastNudge = doc.data['lastNudge'].toDate();
    return new CheckData(id: doc.documentID,description: doc.data['description'], amount: doc.data['amount'], creditorUID: doc.data['creditorUID'], debitorUID: doc.data['debitorUID'], creditorName: doc.data['creditorName'], debitorName: doc.data['debitorName'], date: doc.data['date'].toDate(), paid: doc.data['paid'], lastNudge: lastNudge);
  }
}

class UserData {
  String phone;
  String firstName;
  String lastName;
  String fullName;
  String username;
  String uid;
  List<String> friendUIDs;
  double credit;
  double debt;
  String profilePicURL;

  UserData({this.phone,this.firstName,this.lastName,this.fullName,this.username,this.uid,this.friendUIDs,this.credit,this.debt,this.profilePicURL});

  factory UserData.fromDoc(DocumentSnapshot doc) {
    if(!doc.exists)
      return new UserData();
    else
      return new UserData(phone: doc.data['phone'], firstName: doc.data['firstName'], lastName: doc.data['lastName'], fullName: doc.data['fullName'], username: doc.data['username'], uid: doc.data['uid'], friendUIDs: new List<String>.from(doc.data['friends'],), credit: doc.data['credit'].toDouble(), debt: doc.data['debt'].toDouble(), profilePicURL: doc.data['profilePicURL']);
  }
}