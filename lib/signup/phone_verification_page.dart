import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/signup/user_info_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class VerificationCodePage extends StatefulWidget {
  VerificationCodePage(this.verificationId);
  final String verificationId;
  @override
  _VerificationCodePageState createState() => _VerificationCodePageState(verificationId);
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  _VerificationCodePageState(this._verificationId);
  String _verificationId;
  final TextEditingController _smsController = TextEditingController();
  String _message = '';
  final _formKey = GlobalKey<FormState>();
  bool _incorrect = false;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Form(
        key: _formKey,
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Spacer(flex: 1,),
            Container(
              child: const Text(
                'Please Enter Verification Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                ),
              ),
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
            ),
            Container(
              padding: EdgeInsets.all(8),
              width: 200,
              alignment: Alignment.center,
              child: TextFormField(
                controller: _smsController,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                    labelText: 'Verification Code',
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(8.0),
                    )
                ),
                validator: (value) {
                  if(value.isEmpty)
                    return "Must enter code";
                  else if(_incorrect)
                    return "Code incorrect";
                  else
                    return null;
                },
                onChanged: (value) {
                  if(_incorrect) {
                    setState(() {
                      _incorrect = false;
                    });
                    _formKey.currentState.validate();
                  }
                },
              ),
            ),
            RaisedButton(
              onPressed: () async {
                if(_formKey.currentState.validate()) {
                  Navigator.of(context).push(new MaterialPageRoute(
                      builder: (BuildContext context) {
                        return Theme(
                          data: new ThemeData(
                            brightness: Brightness.light,
                            primarySwatch: Colors.green
                          ),
                          child: new Scaffold(
                            body: new Center(
                              child: new CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }
                  ));
                  String result = await _signInWithPhoneNumber();
                  if(result != null) {
                    DocumentSnapshot userDoc = await Firestore.instance.collection('users').document(result).get();
                    if(userDoc.exists) {
                      Navigator.pushNamed(context, '/home', arguments: result);
                    } else {
                      Navigator.of(context).pushReplacement(
                        new MaterialPageRoute(
                            builder: (BuildContext context) {
                              return new Theme(
                                  data: new ThemeData(
                                      brightness: Brightness.light,
                                      primarySwatch: Colors.green
                                  ),
                                  child: new UserInfoPage(new UserData(uid: result))
                              );
                            }
                        ),
                      );
                    }
                  } else {
                    Navigator.pop(context);
                    _incorrect = true;
                    _formKey.currentState.validate();
                  }
                }
              },
              child: const Text('VERIFY'),
              color: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0)),
            ),
            Spacer(flex: 2,),
          ],
        ),
      ),
    );
  }

  Future<String> _signInWithPhoneNumber() async {
    final AuthCredential credential = PhoneAuthProvider.getCredential(
      verificationId: _verificationId,
      smsCode: _smsController.text,
    );
    FirebaseUser user;
    try {
      user = (await _auth.signInWithCredential(credential)).user;
    } catch(error) {
      return null;
    }
    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);
    if (user != null) {
      return user.uid;
    } else {
      return null;
    }
  }
}