import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/user_data_container.dart';
import 'package:debtcheck/user_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';

import 'home.dart';

class CheckCreateDialog extends StatefulWidget {
  @override
  _CheckCreateDialogState createState() => _CheckCreateDialogState();
}

class _CheckCreateDialogState extends State<CheckCreateDialog> {
  String friendName;
  String friendUID;
  DateTime date = DateTime.now();
  TextEditingController descriptionController = new TextEditingController();
  var amountController = new MoneyMaskedTextController(leftSymbol: '\$', initialValue: 0, decimalSeparator: '.', thousandSeparator: ',');

  @override
  Widget build(BuildContext context) {
    var container = StateContainer.of(context);
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('New Debt Check'),
      ),
      body: new SingleChildScrollView(
        child: new Form(
          child: new Column(
            children: <Widget>[
              new Row(
                children: <Widget>[
                  new Icon(Icons.person),
                  getDebtorDisplay(container.user.uid),
                ],
              ),
              new TextFormField(
                controller: descriptionController,
                decoration: new InputDecoration(
                    labelText: 'Description',
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(8.0),
                    )
                ),
              ),
              new Row(
                children: <Widget>[
                  new Icon(Icons.calendar_today),
                  new Text("${date.month}/${date.day}/${date.year}"),
                  new IconButton(
                    icon: new Icon(Icons.edit),
                    onPressed: () async {
                      DateTime result = await showDatePicker(
                        context: context,
                        firstDate: new DateTime(2019),
                        initialDate: date,
                        lastDate: DateTime.now(),
                      );
                      if(result != null) {
                        setState(() {
                          date = result;
                        });
                      }
                    },
                  ),
                ],
              ),
              new TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: new InputDecoration(
                    labelText: 'Amount',
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(8.0),
                    )
                ),
              ),
              new RaisedButton(
                child: new Text('DONE'),
                onPressed: () {
                  Navigator.of(context).pop(new CheckData(description: descriptionController.text, amount: amountController.numberValue, debitorUID: friendUID, debitorName: friendName, date: date));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getDebtorDisplay(uid) {
    return new Row(
      children: <Widget>[
        if(friendName == null)
          new Text('Name'),
        if(friendName != null)
          new Text(friendName),
        new IconButton(
          icon: new Icon(Icons.edit),
          onPressed: () async {
            DocumentSnapshot userDoc = await Firestore.instance.collection('users').document(uid).get();
            List<dynamic> friends = userDoc.data['friends'];
            UserData user = await showSearch<UserData>(
              context: context,
              delegate: new UserSearchDelegate(exclude: [uid], defaultList: friends.map((uid) => uid.toString()).toList()),
            );
            if(user != null)
              setState(() {
                friendName = user.fullName;
                friendUID = user.uid;
              });
          },
        ),
      ],
    );
  }
}