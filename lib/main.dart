import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:permission_handler/permission_handler.dart';
import 'signup/phone_login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/check_bloc.dart';
import 'bloc/user_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dynamic_theme/dynamic_theme.dart';

void main() async {
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
  static FirebaseAnalytics analytics = FirebaseAnalytics();

  @override
  void initState() {
    super.initState();
    analytics.setAnalyticsCollectionEnabled(true);
    analytics.logAppOpen();
    PermissionHandler().requestPermissions([PermissionGroup.contacts]);
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
            child: DynamicTheme(
              defaultBrightness: MediaQuery.platformBrightnessOf(context),
              data: (brightness) => new ThemeData(
                primarySwatch: Colors.green,
                brightness: brightness,
                buttonTheme: new ButtonThemeData(
                  shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0)),
                  buttonColor: Colors.green,
                ),
              ),
              themedWidgetBuilder: (context, theme) {
                analytics.setUserProperty(name: 'brightness', value: theme.brightness.toString());
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'Debt Check',
                  initialRoute: start,
                  theme: theme,
                  onGenerateRoute: (RouteSettings settings) {
                    switch(settings.name) {
                      case '/signup':
                        return new MaterialPageRoute(
                            builder: (_) {
                              return new Theme(
                                data: new ThemeData(
                                  brightness: Brightness.light,
                                  primarySwatch: Colors.green
                                ),
                                child: PhoneLoginPage()
                              );
                            }
                        );
                      case '/home':
                        _updateFCM(settings.arguments);
                        return new MaterialPageRoute(
                            builder: (context) {
                              print(settings.arguments);
                              BlocProvider.of<UserBloc>(context).add(StartUserBloc(settings.arguments,context));
                              BlocProvider.of<CheckBloc>(context).add(StartCheckBloc());
                              return new HomePage();
                            }
                        );
                      default:
                        return new MaterialPageRoute(
                            builder: (context) {
                              _checkSignin(context);
                              return new Scaffold(
                                body: new Center(
                                  child: new CircularProgressIndicator(),
                                ),
                              );
                            }
                        );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _updateFCM(String uid) async {
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
      if(!userDoc.exists || userDoc.data['uid'] == null)
        Navigator.of(context).pushReplacementNamed('/signup');
      else
        Navigator.of(context).pushReplacementNamed('/home', arguments: user.uid);
    }
  }
}