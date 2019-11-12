import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FindFriendsPage extends StatefulWidget {
  @override
  _FindFriendsPageState createState() => _FindFriendsPageState();
}

class _FindFriendsPageState extends State<FindFriendsPage> {
  int searchtype = 0;
  TextEditingController _queryController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Select Friend'),),
      body: new Column(
        children: <Widget>[
          new DropdownButton(
            items: [
              DropdownMenuItem(
                value: 0,
                child: new Text('Name'),
              ),
              DropdownMenuItem(
                value: 1,
                child: new Text('Username'),
              ),
            ],
          ),
          new TextField(
            controller: _queryController,
            decoration: new InputDecoration(
              prefixIcon: new Icon(Icons.search),
              labelText: 'Name/Username',
              border: new OutlineInputBorder(
                borderRadius: new BorderRadius.circular(8.0),
              )
            ),
            onChanged: (value) {
              _updateQuery(value);
            },
          ),
        ],
      ),
    );
  }
  
  void _updateQuery(String query) {
    QuerySnapshot docs = Firestore.instance.collection('users').where('fullName', )
  }
}