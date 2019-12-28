import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/signup/phone_verification_page.dart';
import 'package:debtcheck/signup/user_info_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../home.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class PhoneLoginPage extends StatefulWidget {
  @override
  _PhoneLoginPageState createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final TextEditingController _phoneNumberController = TextEditingController();

  String _message = '';
  String _verificationId;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Builder(
        builder: (context) =>
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Spacer(flex: 1,),
                Container(
                  child: const Text(
                    'Welcome to Debt Check!',
                    style: TextStyle(
                      fontSize: 22,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                ),
                Container(
                  child: const Text('Get started by verifying your Phone Number'),
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                ),
                Container(height: 12,),
                Container(
                  padding: const EdgeInsets.all(8),
                  width: 250,
                  alignment: Alignment.center,
                  child: TextFormField(
                    controller: _phoneNumberController,
                    inputFormatters: [
                      WhitelistingTextInputFormatter.digitsOnly,
                      _UsNumberTextInputFormatter(),
                    ],
                    decoration: new InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: new Icon(Icons.plus_one),
                      border: new OutlineInputBorder(
                        borderRadius: new BorderRadius.circular(8.0),
                      )
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                RaisedButton(
                  onPressed: () async {
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
                    _verifyPhoneNumber(context);
                  },
                  color: Colors.green,
                  child: const Text('VERIFY'),
                  shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0)),
                ),
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _message,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                Spacer(flex: 2,),
              ],
            ),
      ),
    );
  }

  void _verifyPhoneNumber(context) async {
    setState(() {
      _message = '';
    });
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) async {
      await _auth.signInWithCredential(phoneAuthCredential);
      FirebaseUser user = await _auth.currentUser();
      DocumentSnapshot userDoc = await Firestore.instance.collection('users').document(user.uid).get();
      if(userDoc.exists) {
        Navigator.pushNamed(context, '/home', arguments: user.uid);
      } else {
        Navigator.of(context).pushReplacement(
          new MaterialPageRoute(
              builder: (BuildContext context) {
                return Theme(
                  data: new ThemeData(
                    brightness: Brightness.light,
                    primarySwatch: Colors.green
                  ),
                  child: new UserInfoPage(
                    new UserData(uid: user.uid,)
                  )
                );
              }
          ),
        );
      }
    };

    final PhoneVerificationFailed verificationFailed =
        (AuthException authException) {
      Navigator.of(context).pop();
      setState(() {
        _message =
        'Phone number verification failed. Code: ${authException.code}. Message: ${authException.message}';
      });
    };

    final PhoneCodeSent codeSent =
        (String verificationId, [int forceResendingToken]) async {
      Navigator.of(context).pushReplacement(new MaterialPageRoute(
          builder: (BuildContext context) {
            return new Theme(
                data: new ThemeData(
                    brightness: Brightness.light,
                    primarySwatch: Colors.green
                ),
                child: VerificationCodePage(verificationId),
            );
          }
      ));
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
    };
    String number = "+1 "+_phoneNumberController.text.substring(1,4)+_phoneNumberController.text.substring(6,9)+_phoneNumberController.text.substring(10);
    await _auth.verifyPhoneNumber(
        phoneNumber: number,
        timeout: const Duration(seconds: 5),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout
    );
  }
}

class _UsNumberTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue
      ) {
    final int newTextLength = newValue.text.length;
    int selectionIndex = newValue.selection.end;
    int usedSubstringIndex = 0;
    final StringBuffer newText = StringBuffer();
    if (newTextLength >= 1) {
      newText.write('(');
      if (newValue.selection.end >= 1)
        selectionIndex++;
    }
    if (newTextLength >= 4) {
      newText.write(newValue.text.substring(0, usedSubstringIndex = 3) + ') ');
      if (newValue.selection.end >= 3)
        selectionIndex += 2;
    }
    if (newTextLength >= 7) {
      newText.write(newValue.text.substring(3, usedSubstringIndex = 6) + '-');
      if (newValue.selection.end >= 6)
        selectionIndex++;
    }
    if (newTextLength >= 11) {
      newText.write(newValue.text.substring(6, usedSubstringIndex = 10) + ' ');
      if (newValue.selection.end >= 10)
        selectionIndex++;
    }
    // Dump the rest.
    if (newTextLength >= usedSubstringIndex)
      newText.write(newValue.text.substring(usedSubstringIndex));
    return TextEditingValue(
      text: newText.toString(),
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}