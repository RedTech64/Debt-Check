import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/user_bloc.dart';
import 'home.dart';
import 'bloc/check_bloc.dart';

class CheckList extends StatelessWidget {
  final List<CheckData> checks;
  CheckList(this.checks);

  @override
  Widget build(BuildContext context) {
    return new ListView.builder(
      shrinkWrap: true,
      itemCount: checks.length,
      itemBuilder: (context, index) {
        if(BlocProvider.of<UserBloc>(context).state.userData.uid == checks[index].creditorUID)
          return new CheckCard(checks[index],CheckType.sent);
        else
          return new CheckCard(checks[index],CheckType.received);
      },
    );
  }
}

enum CheckType {sent,received}

class CheckCard extends StatelessWidget {
  final CheckData checkData;
  final CheckType checkType;

  CheckCard(this.checkData,this.checkType);

  @override
  Widget build(BuildContext context) {
    Color amountColor;
    if(checkType == CheckType.received)
      amountColor = Colors.red;
    else
      amountColor = Colors.green;
    return new Card(
      shape: new RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15)
      ),
      child: new Column(
        children: <Widget>[
          new Container(
            padding: EdgeInsets.all(12),
            child: new Row(
              children: <Widget>[
                new Icon(Icons.person, color: Colors.grey,),
                new Container(width: 4,),
                if(checkType == CheckType.sent)
                  new Text(
                    '${checkData.debitorName}',
                    style: new TextStyle(
                      fontSize: 18,
                    ),
                  ),
                if(checkType == CheckType.received)
                  new Text(
                    '${checkData.creditorName}',
                    style: new TextStyle(
                      fontSize: 18,
                    ),
                  ),
                new Spacer(flex: 1,),
                new Text(
                  '\$${checkData.amount.toStringAsFixed(2)}',
                  style: new TextStyle(
                    fontSize: 18,
                    color: amountColor
                  ),
                ),
              ],
            ),
          ),
          new Container(
            padding: EdgeInsets.all(12),
            child: new Row(
              children: <Widget>[
                new Icon(Icons.mode_comment, color: Colors.grey),
                new Container(width: 4,),
                new Text(
                  '${checkData.description}',
                  style: new TextStyle(
                    fontSize: 18,
                  ),
                ),
                new Spacer(flex: 1,),
                new Text(
                  '${checkData.date.month}/${checkData.date.day}/${checkData.date.year}',
                  style: new TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          new Divider(height: 0,),
          if(checkType == CheckType.sent)
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                new FlatButton(
                  child: new Text('MARK AS PAID'),
                  onPressed: () async {
                    var result = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return new AlertDialog(
                          title: new Text('Confirmation'),
                          content: new Text('Are you sure you want to mark this check as paid?'),
                          actions: <Widget>[
                            new FlatButton(
                              child: new Text('NO'),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                            new FlatButton(
                              child: new Text('YES'),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ],
                        );
                      },
                    );
                    if(result == true)
                      BlocProvider.of<CheckBloc>(context).add(MarkAsPaid(checkData));
                  },
                ),
                new FlatButton(
                  child: new Text('NUDGE'),
                  onPressed: () async {
                    var result = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return new AlertDialog(
                          title: new Text('Confirmation'),
                          content: new Text('Are you sure you want to nudge ${checkData.debitorName}?'),
                          actions: <Widget>[
                            new FlatButton(
                              child: new Text('NO'),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                            new FlatButton(
                              child: new Text('YES'),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ],
                        );
                      },
                    );
                    if(result == true)
                      BlocProvider.of<CheckBloc>(context).add(Nudge(checkData));
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}