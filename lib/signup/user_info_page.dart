import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_image_crop/simple_image_crop.dart';

import '../home.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class UserInfoPage extends StatefulWidget {
  final UserData userData;
  UserInfoPage(this.userData);
  @override
  _UserInfoPageState createState() => _UserInfoPageState(this.userData);
}

class _UserInfoPageState extends State<UserInfoPage> {
  UserData userData;
  TextEditingController _firstNameController;
  TextEditingController _lastNameController;
  TextEditingController _usernameController;
  final _formKey = GlobalKey<FormState>();
  bool _taken = false;
  File profilePic;
  _UserInfoPageState(this.userData);

  @override
  void initState() {
    super.initState();
    if(userData.username != null && userData.username != '') {
      _firstNameController = new TextEditingController(text: userData.firstName);
      _lastNameController = new TextEditingController(text: userData.lastName);
      _usernameController = new TextEditingController(text: userData.username);
    } else {
      _firstNameController = new TextEditingController();
      _lastNameController = new TextEditingController();
      _usernameController = new TextEditingController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: SingleChildScrollView(
        child: new Form(
          key: _formKey,
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(height: 75,),
              Container(
                child: const Text(
                  'Please fill out the information below:',
                  style: TextStyle(
                    fontSize: 22,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                width: 200,
                alignment: Alignment.center,
                child: TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    WhitelistingTextInputFormatter(RegExp("[A-Za-z]")),
                  ],
                  decoration: new InputDecoration(
                      labelText: 'First Name',
                      border: new OutlineInputBorder(
                        borderRadius: new BorderRadius.circular(8.0),
                      )
                  ),
                  validator: (value) {
                    if(value.isEmpty)
                      return 'First name required';
                    else
                      return null;
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                width: 200,
                alignment: Alignment.center,
                child: TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    WhitelistingTextInputFormatter(RegExp("[A-Za-z]")),
                  ],
                  decoration: new InputDecoration(
                      labelText: 'Last Name',
                      border: new OutlineInputBorder(
                        borderRadius: new BorderRadius.circular(8.0),
                      )
                  ),
                  validator: (value) {
                    if(value.isEmpty)
                      return 'Last Name required';
                    else
                      return null;
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                width: 200,
                alignment: Alignment.center,
                child: TextFormField(
                  controller: _usernameController,
                  textCapitalization: TextCapitalization.none,
                  inputFormatters: [
                    WhitelistingTextInputFormatter(RegExp("[a-z0-9]")),
                  ],
                  decoration: new InputDecoration(
                    prefix: new Text('@'),
                    labelText: 'Username',
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(8.0),
                    )
                  ),
                  validator: (value) {
                    if(value.length < 5)
                      return '4 character minimum';
                    else if(_usernameExists(value))
                      return 'Username taken';
                    else
                      return null;
                  },
                  onChanged: (value) {
                    _formKey.currentState.validate();
                  },
                ),
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Text('Profile Picture: '),
                  _getProfilePicDisplay(),
                  new IconButton(
                    icon: new Icon(Icons.edit),
                    onPressed: () => _selectImage(),
                  ),
                ],
              ),
              Container(height: 12,),
              RaisedButton(
                onPressed: () async {
                  if(_formKey.currentState.validate()) {
                    Navigator.of(context).push(new MaterialPageRoute(
                        builder: (BuildContext context) {
                          return new Theme(
                            data: Theme.of(context),
                            child: new Scaffold(
                              body: new Center(
                                child: new CircularProgressIndicator(),
                              ),
                            ),
                          );
                        }
                    ));
                    await _createUserDoc();
                    Navigator.pushNamed(context, '/home', arguments: userData.uid);
                  }
                },
                child: const Text('DONE'),
                color: Theme.of(context).accentColor,
                shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getProfilePicDisplay() {
    if(profilePic != null)
      return new CircleAvatar(backgroundImage: FileImage(profilePic),);
    else if(userData.profilePicURL != null && userData.profilePicURL != '')
      return new CircleAvatar(backgroundImage: NetworkImage(userData.profilePicURL),);
    else
      return new Text('None');
  }

  void _selectImage() async {
    File image = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if(image == null)
      return;
    File cropped = await Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (BuildContext context) {
          final imgCropKey = GlobalKey<ImgCropState>();
          return Scaffold(
            backgroundColor: Colors.black,
            resizeToAvoidBottomInset: true,
            extendBody: true,
            body: new ImgCrop(
              key: imgCropKey,
              chipShape: 'circle',
              chipRadius: 150,
              image: FileImage(image),
            ),
            floatingActionButton: new FloatingActionButton(
              child: new Icon(Icons.save),
              onPressed: () async {
                File file = await imgCropKey.currentState.cropCompleted(image, pictureQuality: 400);
                Navigator.of(context).pop(file);
              },
            ),
          );
        }
      )
    );
    setState(() {
      profilePic = cropped;
    });
  }

  bool _usernameExists(String value) {
    Firestore.instance.collection('users').where('username', isEqualTo: value).getDocuments().then((docs) {
      if(docs.documents.length != 0) {
        _taken = true;
        _formKey.currentState.validate();
      } else {
        _formKey.currentState.validate();
        _taken = false;
      }
    });
    if(value == userData.username)
      _taken = false;
    return _taken;
  }
  Future _createUserDoc() async {
    Map<String,bool> searchTerms = {};
    String fullName = _firstNameController.text+" "+_lastNameController.text;
    for(int i = 0; i < fullName.length; i++) {
      searchTerms[fullName.substring(0,i+1).toLowerCase()] = true;
    }
    for(int i = 0; i < _lastNameController.text.length; i++) {
      searchTerms[_lastNameController.text.substring(0,i+1).toLowerCase()] = true;
    }
    for(int i = 0; i < _usernameController.text.length; i++) {
      searchTerms[_usernameController.text.substring(0,i+1).toLowerCase()] = true;
    }
    String url = '';
    if(profilePic != null) {
      StorageReference storageReference = FirebaseStorage().ref().child('/users/'+userData.uid);
      StorageUploadTask uploadTask = storageReference.putFile(profilePic);
      StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
      url = await storageTaskSnapshot.ref.getDownloadURL();
    }
    if(userData.username != null) {
      if(url != '') {
        await Firestore.instance.collection('users').document(userData.uid).updateData({
          'profilePicURL': url,
        });
      }
      return Firestore.instance.collection('users').document(userData.uid).updateData({
        'fullName': _firstNameController.text+" "+_lastNameController.text,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'username': _usernameController.text,
        'searchTerms': searchTerms,
      });

    } else {
      FirebaseUser user = await _auth.currentUser();
      return Firestore.instance.collection('users').document(userData.uid).setData({
        'uid': userData.uid,
        'phone': user.phoneNumber,
        'fullName': _firstNameController.text+" "+_lastNameController.text,
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'username': _usernameController.text,
        'searchTerms': searchTerms,
        'friends': [],
        'credit': 0,
        'debt': 0,
        'profilePicURL': url,
      });
    }
  }
}