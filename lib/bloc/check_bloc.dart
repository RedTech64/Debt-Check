import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/bloc/user_bloc.dart';
import 'package:debtcheck/home.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:http/http.dart' as http;

abstract class CheckEvent extends Equatable{
  const CheckEvent();

  @override
  List<CheckData> get props => [];
}

class StartCheckBloc extends CheckEvent {}

class Update extends CheckEvent {
  final List<CheckData> checkData;

  Update(QuerySnapshot snapshot) : this.checkData = snapshot.documents.map((doc) => new CheckData.fromDoc(doc)).toList();

  @override
  List<CheckData> get props => checkData;
}

class MarkAsPaid extends CheckEvent {
  final CheckData checkData;
  MarkAsPaid(this.checkData);
}

class Nudge extends CheckEvent {
  final CheckData checkData;
  Nudge(this.checkData);
}

class CreateCheck extends CheckEvent {
  final CheckData checkData;
  CreateCheck(this.checkData);
}

abstract class CheckState extends Equatable {
  const CheckState();

  List<CheckData> get received => [];

  List<CheckData> get sent => [];

  num getDebtTo(String uid) => 0;
  num getDebtFrom(String uid) => 0;
  List<CheckData> getFromUser(String uid) => [];

  @override
  List<Object> get props => [];
}

class InitialState extends CheckState {}

class Loaded extends CheckState {
  final List<CheckData> checks;
  final String uid;

  const Loaded(this.checks,this.uid);

  List<CheckData> get received => checks.where((check) => (check.debitorUID == uid)).toList();

  List<CheckData> get sent => checks.where((check) => (check.creditorUID == uid)).toList();

  @override
  num getDebtTo(String uid) {
    List<CheckData> query = checks.where((check) => check.debitorUID == uid).toList();
    num total = 0;
    query.forEach((check) => total += check.amount);
    return total;
  }

  @override
  num getDebtFrom(String uid) {
    List<CheckData> query = checks.where((check) => check.creditorUID == uid).toList();
    num total = 0;
    query.forEach((check) => total += check.amount);
    return total;
  }
  
  List<CheckData> getFromUser(String uid) {
    return checks.where((check) => check.creditorUID == uid || check.debitorUID == uid).toList();
  }

  @override
  List<Object> get props => [checks];
}

class CheckBloc extends Bloc<CheckEvent,CheckState> {
  final UserBloc userBloc;
  StreamSubscription docSubscription;
  StreamSubscription userSubscription;
  static FirebaseAnalytics analytics = FirebaseAnalytics();
  
  CheckBloc({this.userBloc});
  
  @override
  CheckState get initialState => InitialState();

  @override
  Stream<CheckState> mapEventToState(CheckEvent event) async* {
    if(event is StartCheckBloc) {
      userSubscription?.cancel();
      userSubscription = userBloc.listen((state) {
        docSubscription?.cancel();
        docSubscription = Firestore.instance.collection('checks').where('involved', arrayContains: userBloc.state.userData.uid).where('paid', isEqualTo: false).snapshots().listen((data) => add(Update(data)));
      });
    }
    if(event is Update) {
      yield Loaded(event.checkData,userBloc.state.userData.uid);
    }
    if(event is MarkAsPaid) {
      analytics.logEvent(
        name: 'mark_as_paid',
        parameters: <String, dynamic> {
          'days_past': DateTime.now().difference(event.checkData.date).inDays,
        }
      );
      Firestore.instance.collection('checks').document(event.checkData.id).updateData({
        'paid': true,
      });
    }
    if(event is Nudge) {
      analytics.logEvent(
        name: 'nudge',
        parameters: <String, dynamic> {
          'days_past': DateTime.now().difference(event.checkData.date).inDays,
        }
      );
      if(event.checkData.lastNudge == null) {
        http.post(
          'https://us-central1-redtech-debt-check.cloudfunctions.net/nudge',
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'fromName': event.checkData.creditorName,
            'uid': event.checkData.debitorUID,
            'description': event.checkData.description,
            'amount': event.checkData.amount.toStringAsFixed(2),
          }),
        );
      }
      Firestore.instance.collection('checks').document(event.checkData.id).updateData({
        'lastNudge': Timestamp.fromDate(DateTime.now()),
      });
    }
    if(event is CreateCheck) {
      analytics.logEvent(
        name: 'create_check',
        parameters: <String, dynamic> {
          'description': event.checkData.description,
          'amount': event.checkData.amount,
        }
      );
      UserData userData = userBloc.state.userData;
      if(!userData.friendUIDs.contains(event.checkData.debitorUID) && event.checkData.debitorUID[0] != '+') {
        userBloc.add(new AddFriend(new UserData(uid: event.checkData.debitorUID)));
      }
      Firestore.instance.collection('checks').add({
        'description': event.checkData.description,
        'amount': event.checkData.amount,
        'date': Timestamp.fromDate(event.checkData.date),
        'creditorName': userData.fullName,
        'creditorUID': userData.uid,
        'debitorName': event.checkData.debitorName,
        'debitorUID': event.checkData.debitorUID,
        'involved': [userData.uid, event.checkData.debitorUID],
        'paid': false,
        'lastNudge': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  @override
  Future<void> close() {
    docSubscription.cancel();
    return super.close();
  }
}