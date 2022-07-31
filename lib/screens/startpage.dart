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

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:periodtracker/screens/arguments/setuppage.dart';
import 'package:periodtracker/screens/arguments/decryptpage.dart';
import 'package:periodtracker/utilities.dart';

class StartPage extends StatelessWidget {
  const StartPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    Future<String> config = localRead('config.json');
    flutterLocalNotificationsPlugin.cancel(0);
    return FutureBuilder<String>(
      future: config,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if(snapshot.hasData){
          final decryptargs = DecryptPageArguments('Decrypt Data', '${snapshot.data}', false);
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/DecryptPage',
               (route) => false,
               arguments: decryptargs,
            );
          });
        }
        if(snapshot.hasError){
          final setupargs = SetupPageArguments('Create Password');
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/SetupPage',
              (route) => false,
              arguments: setupargs,
            );
          });
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
