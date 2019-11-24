import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/home.dart';
import 'package:equatable/equatable.dart';

abstract class CheckEvent extends Equatable{
  const CheckEvent();

  @override
  List<CheckData> get props => [];
}

class StartCheckBloc extends CheckEvent {}

class Update extends CheckEvent {
  List<CheckData> checkData;

  Update(QuerySnapshot snapshot) {
    this.checkData = snapshot.documents.map((doc) => new CheckData.fromDoc(doc)).toList();
  }

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

class UpdateCheckBlocUser extends CheckEvent {
  final String uid;
  UpdateCheckBlocUser(this.uid);
}

abstract class CheckState extends Equatable {
  const CheckState();

  List<CheckData> get received => [];

  List<CheckData> get sent => [];

  num getDebtTo(String uid) => 0;
  num getCreditTo(String uid) => 0;
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
    List<CheckData> query = checks.where((check) => check.creditorUID == uid).toList();
    num total = 0;
    query.forEach((check) => total += check.amount);
    return total;
  }

  @override
  num getCreditTo(String uid) {
    List<CheckData> query = checks.where((check) => check.debitorUID == uid).toList();
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
  String uid;
  StreamSubscription subscription;
  
  CheckBloc(this.uid);
  
  @override
  CheckState get initialState => InitialState();

  @override
  Stream<CheckState> mapEventToState(CheckEvent event) async* {
    if(event is StartCheckBloc) {
      subscription?.cancel();
      subscription = Firestore.instance.collection('checks').where('involved', arrayContains: uid).where('paid', isEqualTo: false).snapshots().listen((data) => add(Update(data)));
    }
    if(event is Update) {
      yield Loaded(event.checkData,uid);
    }
    if(event is MarkAsPaid) {
      Firestore.instance.collection('checks').document(event.checkData.id).updateData({
        'paid': true,
      });
    }
    if(event is Nudge) {
      //TODO: Implement nudge
    }
    if(event is UpdateCheckBlocUser) {
      this.uid = event.uid;
      subscription?.cancel();
      subscription = Firestore.instance.collection('checks').where('involved', arrayContains: uid).where('paid', isEqualTo: false).snapshots().listen((data) => add(Update(data)));
    }
  }

  @override
  Future<void> close() {
    subscription.cancel();
    return super.close();
  }
}