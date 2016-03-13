// Copyright 2016, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show Random;

import 'package:flutter/material.dart';

void main() => runApp(new FirechatApp());

class FirechatApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "Firechat",
      theme: new ThemeData(
        primarySwatch: Colors.purple,
        accentColor: Colors.orangeAccent[400]
      ),
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => new ChatScreen(),
      }
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  String _user;
  List<Map<String, String>> _messages = <Map<String, String>>[];
  InputValue _currentMessage = InputValue.empty;

  void initState() {
    _user = "Guest${new Random().nextInt(1000)}";
    super.initState();
  }

  void _handleMessageChanged(InputValue value) {
    setState(() {
      _currentMessage = value;
    });
  }

  void _handleMessageAdded(InputValue value) {
    Map<String, String> message = {
      'name': _user,
      'text': value.text,
    };
    setState(() {
      _messages.add(message);
      _currentMessage = InputValue.empty;
    });
  }

  bool get _isComposing => _currentMessage.text.length > 0;

  Widget _buildTextComposer() {
    ThemeData themeData = Theme.of(context);
    return new Column(
      children: <Widget>[
        new Row(
          children: <Widget>[
            new Flexible(
              child: new Input(
                value: _currentMessage,
                hintText: 'Enter message',
                onSubmitted: _handleMessageAdded,
                onChanged: _handleMessageChanged
              )
            ),
            new Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: new IconButton(
                icon: Icons.send,
                onPressed: _isComposing ? () => _handleMessageAdded(_currentMessage) : null,
                color: _isComposing ? themeData.accentColor : themeData.disabledColor
              )
            )
          ]
        )
      ]
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Chatting as $_user")
      ),
      body: new Column(
        children: <Widget>[
          new Flexible(
            child: new Block(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              scrollAnchor: ViewportAnchor.end,
              children: _messages.map((m) => new ChatMessage(m)).toList()
            )
          ),
          _buildTextComposer(),
        ]
      )
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage(Map<String, String> source)
    : name = source['name'], text = source['text'];
  final String name;
  final String text;

  Widget build(BuildContext context) {
    return new Container(
      margin: const EdgeInsets.all(3.0),
      child: new Text("$name: $text")
    );
  }
}
