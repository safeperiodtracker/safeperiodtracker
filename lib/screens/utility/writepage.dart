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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'package:periodtracker/utilities.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter/scheduler.dart';
import 'package:periodtracker/screens/arguments/writepage.dart';

class WritePage extends StatelessWidget {
  const WritePage({Key? key}) : super(key: key);

  Future<int> encrypt(String password, List<int> nonce, List<int> data, int iterations, bool loggedOutNotifs, int loggedOutNotifFreq) async {
    final keyDerivator = Pbkdf2(
      macAlgorithm: Hmac.sha512(),
      iterations: iterations,
      bits: 256,
    );
    SecretKey key = await getKey(keyDerivator, password, nonce);
    final algorithm = AesGcm.with256bits();
    final encNonce = algorithm.newNonce();
    final Map<String, dynamic> config = Map.fromIterables(
      ['nonce', 'iterations', 'logged_out_notifs', 'logged_out_notif_freq'],
      [nonce, iterations, loggedOutNotifs, loggedOutNotifFreq],
    );
    await localWrite('config.json', jsonEncode(config));
    final secretBox = await compute(
      encryptCompute,
      Tuple5<AesGcm, List<int>, SecretKey, List<int>, List<int>>(
        algorithm,
        data,
        key,
        encNonce,
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
      ),
    );
    List<int> dataToWrite = secretBox.concatenation();
    await localWriteAsBytes('data', dataToWrite);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final title = (ModalRoute.of(context)!.settings.arguments as WritePageArguments).title;
    final password = (ModalRoute.of(context)!.settings.arguments as WritePageArguments).password;
    final nonce = (ModalRoute.of(context)!.settings.arguments as WritePageArguments).nonce;
    final data = (ModalRoute.of(context)!.settings.arguments as WritePageArguments).data;
    final iterations = (ModalRoute.of(context)!.settings.arguments as WritePageArguments).iterations;
    final loggedOutNotifs = (ModalRoute.of(context)!.settings.arguments as WritePageArguments).loggedOutNotifs;
    final loggedOutNotifFreq = (ModalRoute.of(context)!.settings.arguments as WritePageArguments).loggedOutNotifFreq;
    Future<int> task = encrypt(password, nonce, data, iterations, loggedOutNotifs, loggedOutNotifFreq);
    return FutureBuilder<int>(
      future: task,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        if(snapshot.hasData){
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            );
          });
        }
        if(snapshot.hasError){
          return Text('${snapshot.error}');
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
