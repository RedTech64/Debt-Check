import 'package:flutter/material.dart';
import 'home.dart';
import 'package:debt_check/user_data_container.dart';

class CheckList extends StatelessWidget {
  final List<CheckData> checks;
  CheckList(this.checks);

  @override
  Widget build(BuildContext context) {
    return new ListView.builder(
      itemCount: checks.length,
      itemBuilder: (context, index) {
        return new CheckCard(checks[index]);
      },
    );
  }
}

class CheckCard extends StatelessWidget {
  final CheckData checkData;

  CheckCard(this.checkData);

  @override
  Widget build(BuildContext context) {
    var container = StateContainer.of(context);
    return new Card(
      child: new Column(
        children: <Widget>[
          if(checkData.creditorUID == container.user.uid)
            new Text('${checkData.debitorName} owes you ${checkData.amount} for ${checkData.description}'),
          if(checkData.debitorName == container.user.uid)
            new Text('You owe ${checkData.creditorName}, ${checkData.amount} for ${checkData.description}'),
        ],
      ),
    );
  }
}