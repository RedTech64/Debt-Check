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

class StartFriendBloc extends UserEvent {}

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
  UserData userData;
  List<UserData> friends;

  @override
  List<Object> get props => [];
}

class InitialState extends UserState {
  final UserData userData = null;
  final List<UserData> friends = [];

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
  final String uid;
  StreamSubscription subscription;

  UserBloc(this.uid);

  @override
  UserState get initialState => InitialState();

  @override
  Stream<UserState> mapEventToState(UserEvent event) async* {
    if(event is StartFriendBloc) {
      subscription?.cancel();
      subscription = Firestore.instance.collection('users').document(uid).snapshots().listen((doc) async {
        List<Future<DocumentSnapshot>> futures = [];
        var userIds = doc.data['friends'];
        userIds.forEach((id) {
          futures.add(Firestore.instance.collection('users').document(id).get());
        });
        List<DocumentSnapshot> docs = await Future.wait(futures);
        add(Update(doc,docs));
      });
    }
    if(event is Update) {
      yield Loaded(event.userData,event.friends,uid);
    }
  }

  @override
  Future<void> close() {
    subscription.cancel();
    return super.close();
  }
}