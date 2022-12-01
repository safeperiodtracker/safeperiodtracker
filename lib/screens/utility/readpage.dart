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
import 'package:cryptography/cryptography.dart';
import 'package:periodtracker/screens/arguments/homepage.dart';
import 'package:periodtracker/utilities.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';
import 'package:periodtracker/screens/arguments/readpage.dart';
import 'package:periodtracker/screens/arguments/decryptpage.dart';

class ReadPage extends StatelessWidget {
  const ReadPage({Key? key}) : super(key: key);

  Future<int> encrypt(password, nonce, iterations) async {
    final keyDerivator = Pbkdf2(
      macAlgorithm: Hmac.sha512(),
      iterations: iterations,
      bits: 256,
    );
    SecretKey key = await getKey(keyDerivator, password, nonce);
    final algorithm = AesGcm.with256bits();
    List<int> data = await localReadAsBytes('data');
    final secretBox = SecretBox.fromConcatenation(
      data,
      nonceLength: 12,
      macLength: 16,
    );
    final decrypted = await compute(
      decryptCompute,
      Tuple4<AesGcm, SecretBox, SecretKey, List<int>>(
        algorithm,
        secretBox,
        key,
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
      ),
    );
    assert(eq(decrypted.sublist(0, 16), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]));
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final title = (ModalRoute.of(context)!.settings.arguments as ReadPageArguments).title;
    final password = (ModalRoute.of(context)!.settings.arguments as ReadPageArguments).password;
    final nonce = (ModalRoute.of(context)!.settings.arguments as ReadPageArguments).nonce;
    final iterations = (ModalRoute.of(context)!.settings.arguments as ReadPageArguments).iterations;
    final config = (ModalRoute.of(context)!.settings.arguments as ReadPageArguments).config;
    Future<int> task = encrypt(password, nonce, iterations);
    return FutureBuilder<int>(
      future: task,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        if(snapshot.hasData){
          final homeargs = HomePageArguments('Home', config);
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/HomePage',
              (route) => false,
              arguments: homeargs,
            );
          });
        }
        if(snapshot.hasError){
          final decryptargs = DecryptPageArguments('Decrypt Data', config, true);
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/DecryptPage',
              (route) => false,
              arguments: decryptargs,
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
