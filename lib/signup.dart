import 'package:debt_check/user_data_container.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
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
                child: const Text('Welcome to Debt Check!'),
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
              ),
              Container(
                child: const Text('Sign Up with your Phone Number'),
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                width: 200,
                alignment: Alignment.center,
                child: TextFormField(
                  controller: _phoneNumberController,
                  inputFormatters: [
                    WhitelistingTextInputFormatter.digitsOnly,
                    _UsNumberTextInputFormatter(),
                  ],
                  decoration: new InputDecoration(
                      labelText: 'Phone Number',
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
                      return new Scaffold(
                        body: new Center(
                          child: new CircularProgressIndicator(),
                        ),
                      );
                    }
                  ));
                  _verifyPhoneNumber(context);
                },
                child: const Text('Verify'),
                color: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(16.0)),
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
        (AuthCredential phoneAuthCredential) {
      _auth.signInWithCredential(phoneAuthCredential);
      setState(() {
        _message = 'Received phone auth credential: $phoneAuthCredential';
      });
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
      Scaffold.of(context).showSnackBar(const SnackBar(
        content: Text('Please check your phone for the verification code.'),
      ));
      Navigator.of(context).pushReplacement(new MaterialPageRoute(
          builder: (BuildContext context) {
            return new VerificationCodePage(verificationId);
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

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Spacer(flex: 1,),
          Container(
            child: const Text('Please enter verification code to verify phone number.'),
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
          ),
          Container(
            padding: EdgeInsets.all(8),
            width: 200,
            alignment: Alignment.center,
            child: TextField(
              controller: _smsController,
              keyboardType: TextInputType.number,
              decoration: new InputDecoration(
                  labelText: 'Verification Code',
                  border: new OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(8.0),
                  )
              ),
            ),
          ),
          RaisedButton(
            onPressed: () async {
              _signInWithPhoneNumber();

            },
            child: const Text('Sign in with phone number'),
            color: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(16.0)),
          ),
          Spacer(flex: 2,),
        ],
      ),
    );
  }

  void _signInWithPhoneNumber() async {
    final AuthCredential credential = PhoneAuthProvider.getCredential(
      verificationId: _verificationId,
      smsCode: _smsController.text,
    );
    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;
    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);
    setState(() {
      if (user != null) {
        var container = StateContainer.of(context);
        container.updateUserInfo(uid: user.uid);
        Navigator.of(context).pushReplacement(
          new MaterialPageRoute(
            builder: (BuildContext context) {
              return new UserInfoPage();
            }
          ),
        );
      } else {
        _message = 'Sign in failed';
      }
    });
  }
}

class UserInfoPage extends StatefulWidget {
  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  TextEditingController _firstNameController = new TextEditingController();
  TextEditingController _lastNameController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Spacer(flex: 1,),
          Container(
            child: const Text('Please fill out the information below:'),
            padding: const EdgeInsets.all(8),
            alignment: Alignment.center,
          ),
          Container(
            padding: const EdgeInsets.all(8),
            width: 200,
            alignment: Alignment.center,
            child: TextFormField(
              controller: _firstNameController,
              decoration: new InputDecoration(
                  labelText: 'First Name',
                  border: new OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(8.0),
                  )
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            width: 200,
            alignment: Alignment.center,
            child: TextFormField(
              controller: _lastNameController,
              decoration: new InputDecoration(
                  labelText: 'Last Name',
                  border: new OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(8.0),
                  )
              ),
            ),
          ),
          RaisedButton(
            onPressed: () async {
              var container = StateContainer.of(context);
              await _createUserDoc(container.user.uid,_firstNameController.text,_lastNameController.text);
              Navigator.pushNamed(context, '/');
            },
            child: const Text('Done'),
            color: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(16.0)),
          ),
          Spacer(flex: 2,),
        ],
      ),
    );
  }

  Future _createUserDoc(String uid, String firstName, String lastName) {
    return Firestore.instance.collection('users').document(uid).setData({
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
    });
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