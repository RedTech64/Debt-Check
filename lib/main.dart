import 'package:debt_check/signup.dart';
import 'package:debt_check/user_data_container.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseAuth _auth = FirebaseAuth.instance;
FirebaseUser _user;

void main() async {
  _user = await _auth.currentUser();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new StateContainer(
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
                  if(container.user == null || container.user.uid == null)
                    return new MaterialPageRoute(
                        builder: (_) {
                          return new SignupPage();
                        }
                    );
                  else {
                    container.updateUserInfo(uid: _user.uid);
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Debt Check"),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.exit_to_app), onPressed: () => _auth.signOut()),
        ],
      ),
      body: Center(
        child: new Text("Hello"),
      ),
    );
  }
}
