import 'package:debt_check/user_data_container.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FindFriendsPage extends StatefulWidget {
  List<String> defaultList = [];
  List<String> exclude = [];
  FindFriendsPage({this.defaultList, this.exclude});

  @override
  _FindFriendsPageState createState() => _FindFriendsPageState(this.defaultList, this.exclude);
}

class _FindFriendsPageState extends State<FindFriendsPage> {
  List<String> defaultList = [];
  List<String> exclude = [];
  List<DocumentSnapshot> queryResults = [];
  TextEditingController _queryController = new TextEditingController();
  _FindFriendsPageState(this.defaultList, this.exclude);

  @override
  void initState() {
    _query("").then((list) {
      setState(() {
        queryResults = list;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Select Friend'),),
      body: new Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: new TextField(
              controller: _queryController,
              decoration: new InputDecoration(
                prefixIcon: new Icon(Icons.search),
                labelText: 'Name/Username',
                border: new OutlineInputBorder(
                  borderRadius: new BorderRadius.circular(8.0),
                )
              ),
              onChanged: (value) async {
                List<DocumentSnapshot> list = await _query(value);
                setState(() {
                  queryResults = list;
                });
              },
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: queryResults.length,
            itemBuilder: (context, index) {
              return new InkWell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      new Text(queryResults[index].data['fullName']),
                      new Text("@"+queryResults[index].data['username']),
                    ],
                  ),
                ),
                onTap: () {
                  var container = StateContainer.of(context);
                  Firestore.instance.collection('users').document(container.user.uid).updateData({
                    'friends': FieldValue.arrayUnion([queryResults[index].documentID]),
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ],
      ),
    );
  }
  
  Future<List<DocumentSnapshot>> _query(String query) async {
    if(query == "") {
      if(defaultList == null || defaultList.isEmpty)
        return [];
      List<Future<DocumentSnapshot>> futures = [];
      defaultList.forEach((uid) {
        futures.add(Firestore.instance.collection('users').document(uid).get());
      });
      List<DocumentSnapshot> docs = await Future.wait(futures);
      return docs;
    }
    QuerySnapshot queryDocs = await Firestore.instance.collection('users').where('searchTerms.'+query.toLowerCase(), isEqualTo: true).limit(5).getDocuments();
    queryDocs.documents.removeWhere((doc) => exclude.contains(doc.documentID));
    return queryDocs.documents;
  }
}