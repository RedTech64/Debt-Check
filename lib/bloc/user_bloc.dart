import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/home.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

abstract class UserEvent extends Equatable{
  const UserEvent();

  @override
  List get props => [];
}

class StartUserBloc extends UserEvent {
  final String uid;
  final BuildContext context;
  StartUserBloc(this.uid,this.context);

  List get props => [uid,context];
}

class Update extends UserEvent {
  final UserData userData;
  final List<UserData> friends;

  Update(DocumentSnapshot userDoc, List<DocumentSnapshot> friendDocs) :
    this.userData = new UserData.fromDoc(userDoc),
    this.friends = friendDocs.map((doc) => new UserData.fromDoc(doc)).toList();

  @override
  List get props => [userData,friends];
}

class AddFriend extends UserEvent {
  final UserData friend;
  AddFriend(this.friend);
}

abstract class UserState extends Equatable {
  final UserData userData = new UserData();
  final List<UserData> friends = [];

  @override
  List<Object> get props => [];
}

class InitialState extends UserState {
  final UserData userData;
  final List<UserData> friends = [];
  InitialState(this.userData);
}

class Loading extends UserState {
  final UserData userData;
  final List<UserData> friends = [];
  Loading(this.userData);

  @override
  List get props => [userData];
}

class Loaded extends UserState {
  final UserData userData;
  final List<UserData> friends;
  final String uid;

  Loaded(this.userData,this.friends,this.uid);

  @override
  List get props => [friends,userData,uid];
}

class UserBloc extends Bloc<UserEvent,UserState> {
  StreamSubscription subscription;
  BuildContext context;
  static FirebaseAnalytics analytics = FirebaseAnalytics();

  @override
  UserState get initialState => InitialState(new UserData(uid: null));

  @override
  Stream<UserState> mapEventToState(UserEvent event) async* {
    if(event is StartUserBloc) {
      context = event.context;
      subscription?.cancel();
      if(event.uid != null && event.uid != "") {
        analytics.setUserId(event.uid);
        subscription = Firestore.instance.collection('users').document(event.uid).snapshots().listen((doc) async {
          if(doc.exists) {
            List<Future<DocumentSnapshot>> futures = [];
            var userIds = doc.data['friends'];
            userIds.forEach((id) {
              futures.add(Firestore.instance.collection('users').document(id).get());
            });
            List<DocumentSnapshot> docs = await Future.wait(futures);
            add(Update(doc,docs));
          }
        });
      }
    }
    if(event is Update) {
      if(event.userData != null && event.userData.debt != null && event.userData.credit != null) {
        Brightness brightness = DynamicTheme.of(context).brightness;
        bool readyForGreen = (brightness == Brightness.light && DynamicTheme.of(context).data.primaryColor != Colors.green) || (brightness == Brightness.dark && DynamicTheme.of(context).data.accentColor != Colors.green);
        bool readyForRed = (brightness == Brightness.light && DynamicTheme.of(context).data.primaryColor != Colors.red) || (brightness == Brightness.dark && DynamicTheme.of(context).data.accentColor != Colors.red);
        if(event.userData.credit >= event.userData.debt && readyForGreen)
          if(brightness == Brightness.light)
            DynamicTheme.of(context).setThemeData(
              _getLightTheme(Colors.green),
            );
          else
            DynamicTheme.of(context).setThemeData(
              _getDarkTheme(Colors.green),
            );
        else if(event.userData.credit < event.userData.debt && readyForRed)
          if(brightness == Brightness.light)
            DynamicTheme.of(context).setThemeData(
              _getLightTheme(Colors.red),
            );
          else
            DynamicTheme.of(context).setThemeData(
              _getDarkTheme(Colors.red),
            );
      }
      yield Loaded(event.userData,event.friends,state.userData.uid);
    }

    if(event is AddFriend) {
      analytics.logEvent(
        name: 'add_friend',
      );
      if(event.friend != null && state.friends.where((friend) => friend.uid == event.friend.uid).length == 0)
        Firestore.instance.collection('users').document(state.userData.uid).updateData({
          'friends': FieldValue.arrayUnion([event.friend.uid]),
        });
    }
  }

  ThemeData _getLightTheme(Color primaryColor) {
    return new ThemeData(
      brightness: Brightness.light,
      indicatorColor: Colors.white,
      primarySwatch: primaryColor,
      buttonTheme: new ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0)),
        buttonColor: primaryColor,
      ),
    );
  }

  ThemeData _getDarkTheme(Color primaryColor) {
    return new ThemeData(
      brightness: Brightness.dark,
      accentColor: primaryColor,
      buttonTheme: new ButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0)),
        buttonColor: primaryColor,
      ),
      tabBarTheme: new TabBarTheme(
        unselectedLabelColor: Colors.white,
        labelColor: primaryColor,
      ),
    );
  }

  @override
  Future<void> close() {
    subscription.cancel();
    return super.close();
  }
}