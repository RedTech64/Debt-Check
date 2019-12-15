import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:debtcheck/bloc/check_bloc.dart';
import 'package:debtcheck/check_list.dart';
import 'package:debtcheck/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/user_bloc.dart';
import 'bloc/check_bloc.dart';
import 'friend_page.dart';
import 'user_search_delegate.dart';

class FriendsTab extends StatefulWidget {
  @override
  _FriendsTabState createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc,UserState>(
      builder: (context, userBlocState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new BlocBuilder<CheckBloc,CheckState>(
              builder: (context, checkBlocState) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: userBlocState.friends.length,
                  itemBuilder: (context, index) {
                    return new FriendCard(userBlocState.friends[index],checkBlocState.getCreditTo(userBlocState.friends[index].uid)-checkBlocState.getDebtTo(userBlocState.friends[index].uid),checkBlocState.getFromUser(userBlocState.friends[index].uid).length);
                  },
                );
              },
            ),
            new FlatButton(
              child: new Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Icon(Icons.add),
                  new Text(' ADD FRIEND'),
                ],
              ),
              onPressed: () async {
                UserData newFriend = await showSearch<UserData>(
                  context: context,
                  delegate: new UserSearchDelegate(exclude: [BlocProvider.of<UserBloc>(context).state.userData.uid, ...userBlocState.friends.map((user) => user.uid)],),
                );
                if(newFriend != null && userBlocState.friends.where((friend) => friend.uid == newFriend.uid).length == 0)
                  Firestore.instance.collection('users').document(BlocProvider.of<UserBloc>(context).state.userData.uid).updateData({
                    'friends': FieldValue.arrayUnion([newFriend.uid]),
                  });
              },
            ),
          ],
        );
      },
    );
  }
}

class FriendCard extends StatelessWidget {
  final UserData userData;
  final num balance;
  final int checkNum;
  FriendCard(this.userData,this.balance,this.checkNum);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: new Card(
        child: Container(
          padding: new EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              new Row(
                children: <Widget>[
                  new Icon(Icons.person, color: Colors.grey,),
                  new Container(width: 4,),
                  new Text(
                    userData.fullName,
                    style: new TextStyle(
                      fontSize: 22.0,
                    ),
                  ),
                  Spacer(flex: 1,),
                  new Text(
                    "\$${balance.toStringAsFixed(2)}",
                    style: new TextStyle(
                      fontSize: 22.0,
                    ),
                  ),
                ],
              ),
              new Row(
                children: <Widget>[
                  new Icon(Icons.comment, color: Colors.grey),
                  new Container(width: 4,),
                  new Text(
                    '$checkNum',
                    style: new TextStyle(
                      fontSize: 22.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        Navigator.of(context).push(
          new MaterialPageRoute(
            builder: (BuildContext context) {
              return new FriendPage(userData);
            },
          ),
        );
      },
    );
  }
}