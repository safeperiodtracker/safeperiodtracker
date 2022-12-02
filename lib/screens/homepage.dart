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

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:periodtracker/screens/arguments/homepage.dart';
import 'package:periodtracker/screens/arguments/settingspage.dart';
import 'package:periodtracker/utilities.dart';
import 'package:indent/indent.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  String? title;
  String? config;
  @override
  Widget build(BuildContext context) {
    title = title ?? (ModalRoute.of(context)!.settings.arguments as HomePageArguments).title;
    config = config ?? (ModalRoute.of(context)!.settings.arguments as HomePageArguments).config;
    flutterLocalNotificationsPlugin.cancel(0);
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? ''),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/SettingsPage',
                arguments: SettingsPageArguments('Settings', config ?? ''),
              ).then((config) => setState(() {this.config = config as String;}));
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
          IconButton(
            onPressed: () {
              showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: AutoSizeText(
                    '''
                    You cannot receive notifications when logged out.
                    
                    If you are logging out for privacy reasons, there is no guarantee that private memory will be cleared. Please restart your device if you are concerned.
                    '''.unindent(),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }
}
