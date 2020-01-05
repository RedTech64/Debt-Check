import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:debtcheck/user_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:intl/intl.dart';
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
                    return userSearchDelegate.getCombinedResults();
                  },
                  chipBuilder: (context, state, userData) {
                    return new InputChip(
                      key: ObjectKey(userData),
                      avatar: new CircularProfileAvatar(
                        userData.profilePicURL,
                        radius: 20,
                        initialsText: new Text(
                          _getInitials(userData),
                          style: new TextStyle(
                              color: Colors.black
                          ),
                        ),
                        cacheImage: true,
                        borderWidth: 0.1,
                        backgroundColor: Colors.grey[200],
                        borderColor: Colors.black,
                      ),
                      label: new Text(userData.fullName),
                      onDeleted: () => state.deleteChip(userData),
                    );
                  },
                  suggestionBuilder: (context, state, userData) {
                    String subtitle;
                    if(userData.username == '')
                      subtitle = 'Send via SMS';
                    else
                      subtitle = '@${userData.username}';
                    return ListTile(
                      key: ObjectKey(userData),
                      leading: new CircularProfileAvatar(
                        userData.profilePicURL,
                        radius: 20,
                        initialsText: new Text(
                          _getInitials(userData),
                          style: new TextStyle(
                              color: Colors.black
                          ),
                        ),
                        cacheImage: true,
                        borderWidth: 0.1,
                        backgroundColor: Colors.grey[200],
                        borderColor: Colors.black,
                      ),
                      title: new Text(userData.fullName),
                      subtitle: new Text(subtitle),
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
                child: const Text('DONE'),
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

  String _getInitials(UserData userData) {
    String initials = '';
    if(userData.firstName != null && userData.fullName.length > 0)
      initials += userData.firstName.substring(0,1);
    if(userData.lastName != null && userData.lastName.length > 0)
      initials += userData.lastName.substring(0,1);
    return initials;
  }
}