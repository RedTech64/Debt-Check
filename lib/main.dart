import 'package:debt_check/signup.dart';
import 'package:debt_check/user_data_container.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';

FirebaseAuth _auth = FirebaseAuth.instance;
FirebaseUser _user;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _user = await _auth.currentUser();
  //_auth.signOut();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String uid;
    if(_user == null)
      uid = null;
    else
      uid = _user.uid;
    return new StateContainer(
      user: new UserData(uid: uid),
      child: new Builder(
        builder: (BuildContext context) {
          return MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            initialRoute: '/',
            onGenerateRoute: (RouteSettings settings) {
              var container = StateContainer.of(context);
              switch(settings.name) {
                default:
                  if((container.user == null || container.user.uid == null))
                    return new MaterialPageRoute(
                        builder: (_) {
                          return new SignupPage();
                        }
                    );
                  else {
                    return new MaterialPageRoute(
                        builder: (_) {
                          return new MyHomePage();
                        }
                    );
                  }
              }
            },
          );
        },
      ),
    );
  }
}
