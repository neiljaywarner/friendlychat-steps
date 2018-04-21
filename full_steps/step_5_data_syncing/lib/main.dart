// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';

final ThemeData kIOSTheme = new ThemeData(
  primarySwatch: Colors.orange,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = new ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);

final googleSignIn = new GoogleSignIn();
final analytics = new FirebaseAnalytics();
final auth = FirebaseAuth.instance;
// TODO: update this.
final reference = FirebaseDatabase.instance.reference().child('messages');


void main() {
  runApp(new FriendlychatApp());
}

// Note: right now it deosn't require login.
// we will want to ensure login before allowing the reporting feature...
// etc.
Future<Null> _ensureLoggedIn() async {
  GoogleSignInAccount user = googleSignIn.currentUser;
  if (user == null)
    user = await googleSignIn.signInSilently();
  if (user == null) {
      user = await googleSignIn.signIn();
      analytics.logLogin();
    }
  if (await auth.currentUser() == null) {
    GoogleSignInAuthentication credentials =
    await googleSignIn.currentUser.authentication;
    await auth.signInWithGoogle(
      idToken: credentials.idToken,
      accessToken: credentials.accessToken,
    );
  }
}

class FriendlychatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "HopeNW Sign in",
      theme: defaultTargetPlatform == TargetPlatform.iOS
          ? kIOSTheme
          : kDefaultTheme,
      home: new ChatScreen(),
    );
  }
}

@override
class VolunteerEntry extends StatelessWidget {
  VolunteerEntry({this.snapshot, this.animation});
  final DataSnapshot snapshot;
  final Animation animation;

  Widget build(BuildContext context) {
    return new SizeTransition(
      sizeFactor: new CurvedAnimation(parent: animation, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: new Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              margin: const EdgeInsets.only(right: 16.0),
              // TODO: Change this to in/out with child being a column i think.
              child: new FlatButton(onPressed: onPressedSignout(snapshot), child: new Text("Sign out"))
              //child: new CircleAvatar(backgroundImage: new NetworkImage(snapshot.value['senderPhotoUrl'])),
            ),
            new Expanded(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Text(
                      "${snapshot.value['name']} (${snapshot.value['phone']}) (IN: ${snapshot.value['signInTime']})",
                      style: Theme.of(context).textTheme.subhead),
                  new Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child:
                    new Text(buildListLine2(snapshot.value['email'], snapshot.value['signOutTime'])),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  onPressedSignout(DataSnapshot snapshot) {
    //TODO: deJsonIfy so we have an entry class
    String name = snapshot.value['name'];
    debugPrint("user has pressed signout for $name");
    //_signout(snapshot);
  }

  //TODO: Remove when cleaned up so we're not in a line1/line2 style
  String buildListLine2(String email, String signOutTime) {
    if (signOutTime.isEmpty) {
      return email;
    } else {
      return "$email (OUT: $signOutTime)";
    }
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textControllerName = new TextEditingController();
  final TextEditingController _textControllerEmail = new TextEditingController();
  final TextEditingController _textControllerPhone = new TextEditingController();

  bool _isComposing = false;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text("HOPE Signup"),
          elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        ),
        body: new Column(children: <Widget>[
          new Flexible(
            child: new FirebaseAnimatedList(
              query: reference,
              sort: (a, b) => b.key.compareTo(a.key),
              padding: new EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, DataSnapshot snapshot, Animation<double> animation) {
                return new VolunteerEntry(snapshot: snapshot, animation: animation);
              },
            ),
          ),
          new Divider(height: 1.0),
          new Container(
            decoration:
                new BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ]));
  }

  Widget _buildTextComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Theme.of(context).accentColor),
      child: new Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: new Row(children: <Widget>[
            new Flexible(
              child: new TextField(
                controller: _textControllerName,
                onChanged: (String text) {setState(() {_isComposing = text.length > 0;}); },
                onSubmitted: null, decoration: new InputDecoration.collapsed(hintText: "Name"),
              ),
            ),
            new Flexible(
              child: new TextField(
                controller: _textControllerPhone,
                keyboardType: TextInputType.phone,
                onSubmitted: null, decoration: new InputDecoration.collapsed(hintText: "Phone"),
              ),
            ),
            new Flexible(
              child: new TextField(
                controller: _textControllerEmail,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: null, decoration: new InputDecoration.collapsed(hintText: "Email"),
              ),
            ),
            new Container(
                margin: new EdgeInsets.symmetric(horizontal: 4.0),
                child: Theme.of(context).platform == TargetPlatform.iOS
                    ? new CupertinoButton(
                        child: new Text("Send"),
                        onPressed: _isComposing
                            ? () => _signUp()
                            : null,
                      )
                    : new IconButton(
                        icon: new Icon(Icons.send),
                        onPressed: _isComposing
                            ? () => _signUp()
                            : null,
                      )),
          ]),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? new BoxDecoration(
                  border:
                      new Border(top: new BorderSide(color: Colors.grey[200])))
              : null),
    );
  }

  // TODO: remove this isComposing stuff
  // TODO: Keep the below original code to consider if/when user needs validated
  // as a signed in firebase user.
 /*
  Future<Null> _handleSubmitted(String text) async {
    _textControllerName.clear();
    setState(() {
      _isComposing = false;
    });
    await _ensureLoggedIn();
   // _sendMessage(text: text);
  }
  */

  Future<Null>  _signUp() async {
    // todo; await _ensureLoggedIn? or await ensure logged in when using admin function...
    // or if db is locked down do it here... or on screen start...
    String name = _textControllerName.text;
    String email = _textControllerEmail.text;
    String phone = _textControllerPhone.text;
    String signInTime = _buildNowString24HrTime();
    reference.push().set({
      'email': email,
      'name': name,
      'phone': phone,
      'signInTime': signInTime,
      'signOutTime': ""
    });
    // TODO: Also push signin time as curren titme when tap...
    _textControllerName.clear();
    _textControllerEmail.clear();
    _textControllerPhone.clear();
    analytics.logEvent(name: 'sign_in_new_user');  }


  void updateInfo({ String signin, String signout}) {
    //reference.p
  }





}
String _buildNowString24HrTime() {
  TimeOfDay timeOfDay = new TimeOfDay.now();
  int minute = timeOfDay.minute;
  if (minute < 10) {
    return "${timeOfDay.hour}:0${timeOfDay.minute}";
  } else {
    return "${timeOfDay.hour}:${timeOfDay.minute}";
  }
}

Future<Null> _signout(DataSnapshot signinRowSnapshot) async {
  // Increment counter in transaction.
  // TODO: Cleanup like Item with toJson etc like in example.
  String signOutTime  = _buildNowString24HrTime();
  String name = signinRowSnapshot.value['name'];
  String email = signinRowSnapshot.value['email'];
  String phone = signinRowSnapshot.value['phone'];
  String signInTime = signinRowSnapshot.value['signInTime'];

  reference.child(signinRowSnapshot.key).remove();
  reference.push().set({
    'email': email,
    'name': name,
    'phone': phone,
    'signInTime': signInTime,
    'signOutTime': signOutTime
  });
  //TODO: on Errror, onSuccess



  //todo: then/on to show error message etc.
  /*
  final TransactionResult transactionResult =
  await _counterRef.runTransaction((MutableData mutableData) async {
    mutableData.value = (mutableData.value ?? 0) + 1;
    return mutableData;
  });

  if (transactionResult.committed) {
    _messagesRef.push().set(<String, String>{
      _kTestKey: '$_kTestValue ${transactionResult.dataSnapshot.value}'
    });
  } else {
    print('Transaction not committed.');
    if (transactionResult.error != null) {
      print(transactionResult.error.message);
    }
  }
  */
}

