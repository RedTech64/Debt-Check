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
    return new FutureBuilder<List<UserData>>(
      future: searchUsers(),
      builder: (context, future) {
        if(future.connectionState == ConnectionState.waiting)
          return new CircularProgressIndicator();
        future.data.removeWhere((user) => exclude.contains(user.uid));
        return new ListView.builder(
          itemCount: future.data.length,
          itemBuilder: (context, index) => _getUserCard(future.data[index], context),
        );
      },
    );
  }

  Future<List<UserData>> searchUsers() async {
    if(query == "") {
      if(defaultList == null || defaultList.isEmpty)
        return [];
      List<Future<DocumentSnapshot>> futures = [];
      defaultList.forEach((uid) {
        futures.add(Firestore.instance.collection('users').document(uid).get());
      });
      List<DocumentSnapshot> docs = await Future.wait(futures);
      return docs.map((doc) => new UserData.fromDoc(doc));
    } else {
      QuerySnapshot docs = await Firestore.instance.collection('users').where('searchTerms.'+query.toLowerCase(), isEqualTo: true).limit(5).getDocuments();
      return docs.documents.map((doc) => new UserData.fromDoc(doc)).toList();
    }
  }

  Widget _getUserCard(UserData userData, context) {
      return new ListTile(
        title: new Text(userData.fullName),
        subtitle: new Text('@'+userData.username),
        onTap: () {
          close(context, userData);
        },
      );
  }
}