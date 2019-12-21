import 'package:debtcheck/check_list.dart';
import 'package:debtcheck/home.dart';
import 'package:flutter/material.dart';

class CheckPage extends StatelessWidget {
  final String title;
  final List<CheckData> checks;

  CheckPage(this.title,this.checks);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: Text(title),
      ),
      body: new CheckList(checks),
    );
  }
}