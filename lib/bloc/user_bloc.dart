import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/home.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class UserEvent extends Equatable{
  const UserEvent();

  @override
  List<UserData> get props => [];
}

class StartUserBloc extends UserEvent {
  final String uid;
  final BuildContext context;
  StartUserBloc(this.uid,this.context);
}

class Update extends UserEvent {
  UserData userData;
  List<UserData> friends;

  Update(DocumentSnapshot userDoc, List<DocumentSnapshot> friendDocs) {
    this.userData = new UserData.fromDoc(userDoc);
    this.friends = friendDocs.map((doc) => new UserData.fromDoc(doc)).toList();
  }

  @override
  List<UserData> get props => friends;
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
  List<Object> get props => [userData];
}

class Loaded extends UserState {
  final UserData userData;
  final List<UserData> friends;
  final String uid;

  Loaded(this.userData,this.friends,this.uid);

  @override
  List<Object> get props => [friends,userData,uid];
}

class UserBloc extends Bloc<UserEvent,UserState> {
  StreamSubscription subscription;
  BuildContext context;

  @override
  UserState get initialState => InitialState(new UserData(uid: null));

  @override
  Stream<UserState> mapEventToState(UserEvent event) async* {
    if(event is StartUserBloc) {
      context = event.context;
      if(event.uid != null && event.uid != "") {
        subscription?.cancel();
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
        yield InitialState(new UserData(uid: event.uid));
      }
    }
    if(event is Update) {
      if(event.userData != null && event.userData.debt != null && event.userData.credit != null) {
        print(event.userData.debt);
        print(DynamicTheme.of(context).data.primaryColor);
        if(event.userData.credit >= event.userData.debt && DynamicTheme.of(context).data.primaryColor != Colors.green)
          DynamicTheme.of(context).setThemeData(
            new ThemeData(primarySwatch: Colors.green),
          );
        else if(event.userData.credit < event.userData.debt && DynamicTheme.of(context).data.primaryColor != Colors.red)
          DynamicTheme.of(context).setThemeData(
            new ThemeData(primarySwatch: Colors.red),
          );
      }
      yield Loaded(event.userData,event.friends,state.userData.uid);
    }
  }

  @override
  Future<void> close() {
    subscription.cancel();
    return super.close();
  }
}