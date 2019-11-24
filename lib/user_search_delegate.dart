import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'home.dart';

class UserSearchDelegate extends SearchDelegate<UserData> {
  List<String> defaultList = [];
  List<String> exclude = [];

  UserSearchDelegate({this.defaultList, this.exclude});

  @override
  List<Widget> buildActions(BuildContext context) {
    // TODO: implement buildActions
    return null;
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: BackButtonIcon(),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if(query == "") {
      if(defaultList == null || defaultList.isEmpty)
        return new Container();
      List<Future<DocumentSnapshot>> futures = [];
      defaultList.forEach((uid) {
        futures.add(Firestore.instance.collection('users').document(uid).get());
      });
      return new FutureBuilder<List<DocumentSnapshot>>(
        future: Future.wait(futures),
        builder: (context, future) {
          if(future.connectionState == ConnectionState.waiting)
            return new CircularProgressIndicator();
          return ListView.builder(
            itemCount: future.data.length,
            itemBuilder: (context, index) => _getUserCard(future.data[index], context),
          );
        },
      );
    } else {
      return new FutureBuilder<QuerySnapshot>(
        future: Firestore.instance.collection('users').where('searchTerms.'+query.toLowerCase(), isEqualTo: true).limit(5).getDocuments(),
        builder: (context, future) {
          if(future.connectionState == ConnectionState.waiting)
            return new CircularProgressIndicator();
          List<DocumentSnapshot> queryDocs = future.data.documents;
          queryDocs.removeWhere((doc) => exclude.contains(doc.documentID));
          return new ListView.builder(
            itemCount: queryDocs.length,
            itemBuilder: (context, index) => _getUserCard(queryDocs[index], context),
          );
        },
      );
    }
  }

  Widget _getUserCard(DocumentSnapshot userDoc, context) {
      return new ListTile(
        title: new Text(userDoc['fullName']),
        subtitle: new Text('@'+userDoc['username']),
        onTap: () {
          close(context, new UserData(firstName: userDoc.data['firstName'], lastName: userDoc.data['lastName'], fullName: userDoc.data['fullName'], username: userDoc.data['username'], uid: userDoc.data['uid']));
        },
      );
  }
}