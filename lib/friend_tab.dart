import 'package:debtcheck/bloc/check_bloc.dart';
import 'package:debtcheck/check_list.dart';
import 'package:debtcheck/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/user_bloc.dart';
import 'bloc/check_bloc.dart';

class FriendsTab extends StatefulWidget {
  @override
  _FriendsTabState createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc,UserState>(
      builder: (context, userBlocState) {
        return new BlocBuilder<CheckBloc,CheckState>(
          builder: (context, checkBlocState) {
            return ListView.builder(
              itemCount: userBlocState.friends.length,
              itemBuilder: (context, index) {
                return new FriendCard(userBlocState.friends[index],checkBlocState.getCreditTo(userBlocState.friends[index].uid)-checkBlocState.getDebtTo(userBlocState.friends[index].uid));
              },
            );
          },
        );
      },
    );
  }
}

class FriendCard extends StatelessWidget {
  final UserData userData;
  final num balance;
  FriendCard(this.userData,this.balance);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: new Card(
        child: Container(
          padding: new EdgeInsets.all(8.0),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Text(
                userData.fullName,
                style: new TextStyle(
                  fontSize: 22.0,
                ),
              ),
              new Text(
                "\$${balance.toStringAsFixed(2)}",
                style: new TextStyle(
                  fontSize: 22.0,
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          new MaterialPageRoute(
            builder: (BuildContext context) {
              return new Scaffold(
                appBar: new AppBar(title: new Text(userData.fullName),),
                body: BlocBuilder<CheckBloc,CheckState>(
                  builder: (context, state) {
                    return new CheckList(state.getFromUser(userData.uid));
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}