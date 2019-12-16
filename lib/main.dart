import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/check_bloc.dart';
import 'bloc/user_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String start = '';
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String fcmToken;

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.requestNotificationPermissions();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
      },
      onLaunch: (Map<String, dynamic> message) async {
      },
      onResume: (Map<String, dynamic> message) async {
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return new BlocProvider(
      create: (BuildContext context) => UserBloc(),
      child: new Builder(
        builder: (BuildContext context) {
          return BlocProvider<CheckBloc>(
            create: (BuildContext context) => CheckBloc(userBloc: BlocProvider.of<UserBloc>(context)),
            child: MaterialApp(
              title: 'Debt Check',
              initialRoute: start,
              onGenerateRoute: (RouteSettings settings) {
                switch(settings.name) {
                  case '/signup':
                    return new MaterialPageRoute(
                        builder: (_) {
                          return new SignupPage();
                        }
                    );
                  case '/home':
                    _updateFCM(settings.arguments);
                    return new MaterialPageRoute(
                        builder: (context) {
                          BlocProvider.of<UserBloc>(context).add(StartUserBloc(settings.arguments));
                          BlocProvider.of<CheckBloc>(context).add(StartCheckBloc());
                          return new HomePage();
                        }
                    );
                  default:
                    return new MaterialPageRoute(
                        builder: (context) {
                          _checkSignin(context);
                          return new CircularProgressIndicator();
                        }
                    );
                }
              },
            ),
          );
        },
      ),
    );
  }

  ThemeData _getTheme(UserState state) {
    UserData userData = state.userData;
    if(userData.uid == null || userData.debt <= userData.credit)
      return new ThemeData(
        primaryColor: Colors.green,
      );
    else
      return new ThemeData(
        primaryColor: Colors.red,
      );
  }

  void _updateFCM(String uid) async {
    print(uid);
    String token = await _firebaseMessaging.getToken();
    Firestore.instance.collection('users').document(uid).updateData({
      'fcmToken': token,
    });
  }

  void _checkSignin(context) async {
    FirebaseUser user = await _auth.currentUser();
    if(user == null || user.uid == null) {
      Navigator.of(context).pushReplacementNamed('/signup');
    } else {
      DocumentSnapshot userDoc = await Firestore.instance.collection('users').document(user.uid).get();
      if(!userDoc.exists)
        Navigator.of(context).pushReplacementNamed('/signup');
      else
        Navigator.of(context).pushReplacementNamed('/home', arguments: user.uid);
    }
  }
}
