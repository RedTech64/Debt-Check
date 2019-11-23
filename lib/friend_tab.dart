import 'package:debt_check/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/user_bloc.dart';

class FriendsTab extends StatefulWidget {
  @override
  _FriendsTabState createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc,UserState>(
      builder: (context, state) {
        return ListView.builder(
          itemCount: state.friends.length,
          itemBuilder: (context, index) {
            return new FriendCard(state.friends[index]);
          },
        );
      },
    );
  }
}

class FriendCard extends StatelessWidget {
  final UserData userData;
  FriendCard(this.userData);

  @override
  Widget build(BuildContext context) {
    return new Text(userData.fullName);
  }
}