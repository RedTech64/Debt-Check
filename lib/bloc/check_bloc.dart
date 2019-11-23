import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debt_check/home.dart';
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

abstract class CheckState extends Equatable {
  const CheckState();

  List<CheckData> get received => [];

  List<CheckData> get sent => [];

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
  List<Object> get props => [checks];
}

class CheckBloc extends Bloc<CheckEvent,CheckState> {
  final String uid;
  StreamSubscription subscription;
  
  CheckBloc(this.uid);
  
  @override
  CheckState get initialState => InitialState();

  @override
  Stream<CheckState> mapEventToState(CheckEvent event) async* {
    if(event is StartCheckBloc) {
      subscription?.cancel();
      subscription = Firestore.instance.collection('checks').where('involved', arrayContains: uid).snapshots().listen((data) => add(Update(data)));
    }
    if(event is Update) {
      yield Loaded(event.checkData,uid);
    }
  }

  @override
  Future<void> close() {
    subscription.cancel();
    return super.close();
  }
}