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
import 'package:periodtracker/screens/arguments/settingspage.dart';
import 'package:periodtracker/utilities.dart';

List<String> intervals = ['Every Minute', 'Hourly', 'Daily', 'Weekly'];

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() {
    return SettingsPageState();
  }
}

class SettingsPageState extends State<SettingsPage> {
  bool? _loggedOutNotifs;
  bool? _notifs;
  int? _loggedOutNotifFreq;
  String? config;

  @override
  Widget build(BuildContext context) {
    final title = (ModalRoute.of(context)!.settings.arguments as SettingsPageArguments).title;
    config = config ?? (ModalRoute.of(context)!.settings.arguments as SettingsPageArguments).config;
    Map<String, dynamic> confJSON = jsonDecode(config ?? '');
    _loggedOutNotifs = _loggedOutNotifs ?? confJSON['logged_out_notifs'] as bool;
    _loggedOutNotifFreq = _loggedOutNotifFreq ?? confJSON['logged_out_notif_freq'] as int;
    _notifs = _notifs ?? confJSON['notifs'] as bool;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: WillPopScope(
          onWillPop: () async {
            Navigator.pop(context, config);
            return false;
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SwitchListTile(
                title: const Text('Send Cycle Notifications'),
                value: _notifs as bool,
                onChanged: (bool value) {
                  setState(() {
                    _notifs = value;
                    confJSON['notifs'] = value;
                    localWrite('config.json', jsonEncode(confJSON));
                    config = jsonEncode(confJSON);
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Notify When Logged Out'),
                value: _loggedOutNotifs as bool,
                onChanged: (bool value) {
                  setState(() {
                    _loggedOutNotifs = value;
                    confJSON['logged_out_notifs'] = value;
                    localWrite('config.json', jsonEncode(confJSON));
                    config = jsonEncode(confJSON);
                  });
                },
              ),
              const Text('Frequency of Notifications When Logged Out'),
              DropdownButton<String>(
                value: intervals[_loggedOutNotifFreq ?? 2],
                items: intervals.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _loggedOutNotifFreq = intervals.indexOf(value ?? 'Daily');
                    confJSON['logged_out_notif_freq'] = _loggedOutNotifFreq;
                    localWrite('config.json', jsonEncode(confJSON));
                    config = jsonEncode(confJSON);
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
