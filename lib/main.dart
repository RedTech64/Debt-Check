import 'package:debtcheck/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/check_bloc.dart';
import 'bloc/user_bloc.dart';

FirebaseAuth _auth = FirebaseAuth.instance;

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

  @override
  Widget build(BuildContext context) {
    return new BlocProvider(
      builder: (BuildContext context) => UserBloc(),
      child: new Builder(
        builder: (BuildContext context) {
          return BlocProvider<CheckBloc>(
            builder: (BuildContext context) => CheckBloc(userBloc: BlocProvider.of<UserBloc>(context)),
            child: MaterialApp(
              title: 'Debt Check',
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
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
                    return new MaterialPageRoute(
                        builder: (_) {
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

  void _checkSignin(context) async {
    FirebaseUser user = await _auth.currentUser();
    if(user == null || user.uid == null)
      Navigator.of(context).pushReplacementNamed('/signup');
    else {
      BlocProvider.of<UserBloc>(context).add(StartUserBloc(user.uid));
      BlocProvider.of<CheckBloc>(context).add(StartCheckBloc());
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }
}
