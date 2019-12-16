import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/home.dart';
import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable{
  const UserEvent();

  @override
  List<UserData> get props => [];
}

class StartUserBloc extends UserEvent {
  final String uid;
  StartUserBloc(this.uid);
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
  List<Object> get props => [friends];
}

class UserBloc extends Bloc<UserEvent,UserState> {
  StreamSubscription subscription;

  @override
  UserState get initialState => InitialState(new UserData(uid: null));

  @override
  Stream<UserState> mapEventToState(UserEvent event) async* {
    if(event is StartUserBloc) {
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
      yield Loaded(event.userData,event.friends,state.userData.uid);
    }
  }

  @override
  Future<void> close() {
    subscription.cancel();
    return super.close();
  }
}