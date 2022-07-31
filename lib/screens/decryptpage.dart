/*
Safe Period Tracker
Copyright (C) 2022  The safeperiodtracker Team

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:periodtracker/screens/arguments/decryptpage.dart';
import 'package:periodtracker/screens/arguments/readpage.dart';
import 'package:periodtracker/screens/arguments/shredpage.dart';
import 'package:periodtracker/utilities.dart';

class DecryptForm extends StatefulWidget {
  const DecryptForm({super.key, required this.config});
  final String config;

  @override
  DecryptFormState createState() {
    return DecryptFormState();
  }
}

class DecryptFormState extends State<DecryptForm> {
  final _formKey = GlobalKey<FormState>();
  final pwController = TextEditingController();

  @override
  void dispose() {
    pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TextFormField(
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                hintText: 'Password',
              ),
              obscureText: true,
              controller: pwController,
              enableSuggestions: false,
              autocorrect: false,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                return null;
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Map<String, dynamic> confJSON = jsonDecode(widget.config);
                final readargs = ReadPageArguments(
                  'Working',
                  pwController.text,
                  confJSON['nonce'].cast<int>(),
                  confJSON['iterations'] as int,
                  widget.config,
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/ReadPage',
                  (route) => false,
                  arguments: readargs,
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class DecryptPage extends StatefulWidget {
  const DecryptPage({super.key});

  @override
  DecryptPageState createState() {
    return DecryptPageState();
  }
}

class DecryptPageState extends State<DecryptPage> {
  bool? _notifs;

  @override
  Widget build(BuildContext context) {
    final title = (ModalRoute.of(context)!.settings.arguments as DecryptPageArguments).title;
    final config = (ModalRoute.of(context)!.settings.arguments as DecryptPageArguments).config;
    final failed = (ModalRoute.of(context)!.settings.arguments as DecryptPageArguments).failed;
    flutterLocalNotificationsPlugin.cancel(0);
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        '0', 'logged out notifs',
        channelDescription: 'logged out notifs',
        importance: Importance.max,
        priority: Priority.high);
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    Map<String, dynamic> confJSON = jsonDecode(config);
    _notifs = _notifs ?? confJSON['logged_out_notifs'] as bool;
    List<RepeatInterval> intervalCodes = [RepeatInterval.everyMinute, RepeatInterval.hourly, RepeatInterval.daily, RepeatInterval.weekly];
    if(_notifs ?? true) {
      flutterLocalNotificationsPlugin.periodicallyShow(0, 'You Are Logged Out',
          'Log back in to receive notifications about your cycle.', intervalCodes[confJSON['logged_out_notif_freq'] as int],
          platformChannelSpecifics,
          androidAllowWhileIdle: true);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            (failed) ? Text(
              'Failed to decrypt!',
              style: TextStyle(
                color: Colors.red[400],
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ) : const Text(''),
            DecryptForm(config: config),
            ElevatedButton(
              onPressed: () {
                final shredargs = ShredPageArguments('Shred Data');
                Navigator.pushNamed(
                  context,
                  '/ShredPage',
                  arguments: shredargs,
                );
              },
              child: const Text('Shred Data'),
            ),
            SwitchListTile(
              title: const Text('Notify When Logged Out'),
              value: _notifs as bool,
              onChanged: (bool value) {
                setState(() {
                  _notifs = value;
                  confJSON['logged_out_notifs'] = value;
                  localWrite('config.json', jsonEncode(confJSON));
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
