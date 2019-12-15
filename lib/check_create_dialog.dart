import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/user_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:intl/intl.dart';
import 'bloc/user_bloc.dart';
import 'home.dart';

class CheckCreateDialog extends StatefulWidget {
  @override
  _CheckCreateDialogState createState() => _CheckCreateDialogState();
}

class _CheckCreateDialogState extends State<CheckCreateDialog> {
  String friendName;
  String friendUID;
  DateTime date = DateTime.now();
  TextEditingController descriptionController;
  UserSearchDelegate userSearchDelegate;
  var amountController;
  TextEditingController dateController;
  List<UserData> users;
  final GlobalKey<FormBuilderState> _formkey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    descriptionController = new TextEditingController();
    amountController = new MoneyMaskedTextController(leftSymbol: '', initialValue: 0, decimalSeparator: '.', thousandSeparator: ',');
    userSearchDelegate = new UserSearchDelegate();
    dateController = new TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('New Debt Check'),
      ),
      body: new SingleChildScrollView(
        child: new FormBuilder(
          key: _formkey,
          child: new Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FormBuilderChipsInput(
                  attribute: 'users_selector',
                  decoration: new InputDecoration(
                    prefixIcon: new Icon(Icons.people),
                    labelText: 'Users',
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(8.0),
                    )
                  ),
                  findSuggestions: (String query) {
                    userSearchDelegate.query = query;
                    return userSearchDelegate.searchUsers();
                  },
                  chipBuilder: (context, state, userData) {
                    return new InputChip(
                      key: ObjectKey(userData),
                      label: new Text(userData.fullName),
                      onDeleted: () => state.deleteChip(userData),
                    );
                  },
                  suggestionBuilder: (context, state, userData) {
                    print('build');
                    return ListTile(
                      key: ObjectKey(userData),
                      title: new Text(userData.fullName),
                      subtitle: new Text('@'+userData.username),
                      onTap: () => state.selectSuggestion(userData),
                    );
                  },
                  onChanged: (users) {
                    this.users = users.cast<UserData>();
                    //this.users = ;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: new FormBuilderDateTimePicker(
                  attribute: 'date',
                  initialValue: new DateTime.now(),
                  inputType: InputType.date,
                  controller: dateController,

                  format: DateFormat('MM/dd/yyyy'),
                  decoration: new InputDecoration(
                    prefixIcon: new Icon(Icons.calendar_today),
                    labelText: 'Date',
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(8.0),
                    )
                  ),
                  onChanged: (DateTime date) {
                    this.date = date;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: new TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: new InputDecoration(
                    prefixIcon: new Icon(Icons.attach_money),
                    labelText: 'Amount',
                    border: new OutlineInputBorder(
                      borderRadius: new BorderRadius.circular(8.0),
                    )
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: new TextFormField(
                  controller: descriptionController,
                  decoration: new InputDecoration(
                      prefixIcon: new Icon(Icons.comment),
                      labelText: 'Description',
                      border: new OutlineInputBorder(
                        borderRadius: new BorderRadius.circular(8.0),
                      )
                  ),
                ),
              ),
              new RaisedButton(
                child: new Text('DONE'),
                onPressed: () {
                  _formkey.currentState.save();
                  if (_formkey.currentState.validate()) {
                    List<CheckData> checks = [];
                    users.forEach((user) => checks.add(new CheckData(description: descriptionController.text, amount: amountController.numberValue, debitorUID: user.uid, debitorName: user.fullName, date: date)));
                    Navigator.of(context).pop(checks);
                  } else {
                    print("validation failed");
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}