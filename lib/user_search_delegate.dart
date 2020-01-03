import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'home.dart';

class UserSearchDelegate extends SearchDelegate<UserData> {
  List<String> defaultList = [];
  List<String> exclude = [];

  UserSearchDelegate({this.defaultList, this.exclude});

  @override
  ThemeData appBarTheme(BuildContext context) {
    ThemeData theme = DynamicTheme.of(context).data;
    if(DynamicTheme.of(context).brightness == Brightness.light) {
      return new ThemeData(
        primaryColor: theme.primaryColor,
      );
    } else {
      return new ThemeData(
        primaryColor: new Color.fromRGBO(33, 33, 3, 0),
        accentColor: theme.accentColor,
        textTheme: new TextTheme(
          title: new TextStyle(color: Colors.white),
        ),
      );
    }

  }

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
          return Center(child: new CircularProgressIndicator());
        future.data.removeWhere((user) => exclude.contains(user.uid));
        return new ListView.builder(
          itemCount: future.data.length,
          itemBuilder: (context, index) => _getUserCard(future.data[index], context),
        );
      },
    );
  }

  Future<List<UserData>> getCombinedResults() async {
    List<UserData> list = await searchUsers();
    List<UserData> contacts = await searchContacts();
    Map<String,bool> captured = {};
    list.forEach((userData) => captured[userData.phone] = true);
    list.addAll(contacts.where((userData) => !captured.containsKey(userData.phone)));
    return list;

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
      List<UserData> list = [];
      list.addAll(docs.documents.map((doc) => new UserData.fromDoc(doc)));
      return list;
    }
  }

  Future<List<UserData>> searchContacts() async {
    Iterable<Contact> contacts = await ContactsService.getContacts(query: query, withThumbnails: false);
    List<UserData> list = [];
    for(Contact contact in contacts) {
      String phone;
      if(contact.phones.length == 0)
        phone = '';
      else {
        phone = contact.phones.elementAt(0).value;
        phone = phone.replaceAll(' ', '');
        phone = phone.replaceAll('-', '');
        phone = phone.replaceAll(')', '');
        phone = phone.replaceAll('(', '');
        if(phone[0] != '+')
          phone = '+1'+phone;
      }
      String lastName;
      if(contact.familyName == null)
        lastName = '';
      else
        lastName = contact.familyName;
      list.add(new UserData(firstName: contact.givenName, lastName: lastName, profilePicURL: '', fullName: contact.displayName, username: phone, phone: phone));
    }
    return list;
  }

  Widget _getUserCard(UserData userData, context) {
      return new ListTile(
        leading: new CircularProfileAvatar(
          userData.profilePicURL,
          radius: 20,
          elevation: 0,
          borderColor: Colors.black,
          borderWidth: 0.1,
          backgroundColor: Colors.grey[200],
          initialsText: new Text(
            userData.firstName.substring(0,1)+userData.lastName.substring(0,1),
            style: new TextStyle(
                color: Colors.black
            ),
          ),
        ),
        title: new Text(userData.fullName),
        subtitle: new Text('@'+userData.username),
        onTap: () {
          close(context, userData);
        },
      );
  }
}