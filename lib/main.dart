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
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/scheduler.dart';
import 'package:tuple/tuple.dart';
import 'package:collection/collection.dart';

import 'home.dart';

void main() {
  runApp(const PrivatePeriodTracker());
}

class PrivatePeriodTracker extends StatelessWidget {
  const PrivatePeriodTracker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Private Period Tracker',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) {
          return const StartPage(title: 'Working');
        }
      }
    );
  }
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> _localFile(String filename) async {
  final path = await _localPath;
  return File('$path/$filename');
}

Future<String> _localRead(String filename) async {
  final file = await _localFile(filename);
  return await file.readAsString();
}

Future<void> _localWrite(String filename, String contents) async {
  final file = await _localFile(filename);
  await file.writeAsString(contents);
}

Future<List<int>> _localReadAsBytes(String filename) async {
  final file = await _localFile(filename);
  return await file.readAsBytes();
}

Future<void> _localWriteAsBytes(String filename, List<int> contents) async {
  final file = await _localFile(filename);
  await file.writeAsBytes(contents);
}

Future<void> _localSchneier(File file, int length) async {
  List<int> write = [];
  for(int i = 0;i<length;i++){
    write.add(0x00);
  }
  await file.writeAsBytes(write);
  write = [];
  for(int i = 0;i<length;i++){
    write.add(0xff);
  }
  await file.writeAsBytes(write);
  var rng = Random.secure();
  for(int i = 0;i<5;i++){
    write = [];
    for(int j = 0;j<length;j++){
      write.add(rng.nextInt(256));
    }
    await file.writeAsBytes(write);
  }
}

Future<void> _localDoDE(File file, int length) async{
  List<int> write = [];
  for(int i = 0;i<length;i++){
    write.add(0x00);
  }
  await file.writeAsBytes(write);
  write = [];
  for(int i = 0;i<length;i++){
    write.add(0xff);
  }
  await file.writeAsBytes(write);
  var rng = Random.secure();
  write = [];
  for(int i = 0;i<length;i++){
    write.add(rng.nextInt(256));
  }
  await file.writeAsBytes(write);
}

Future<void> _localDoDECE(File file, int length) async {
  await _localDoDE(file, length);
  var rng = Random.secure();
  List<int> write = [];
  for(int i = 0;i<length;i++){
    write.add(rng.nextInt(256));
  }
  await file.writeAsBytes(write);
  await _localDoDE(file, length);
}

Future<void> _localShredFile(String filename, String? method) async {
  final file = await _localFile(filename);
  final length = await file.length();
  switch(method) {
    case 'Bruce Schneier\'s Algorithm': {
      await _localSchneier(file, length);
    }
    break;
    case 'U.S. DoD 5220.22-M (E)': {
      await _localDoDE(file, length);
    }
    break;
    case 'U.S. DoD 5220.22-M (ECE)': {
      await _localDoDECE(file, length);
    }
    break;
    default: {
      await _localDoDECE(file, length);
    }
  }
  List<int> write = [];
  /*
    I don't know much about data erasure, maybe this will make it look like there never was any data? random bits on a storage medium might be suspicious
  */
  for(int i = 0;i<length;i++){
    write.add(0);
  }
  await file.writeAsBytes(write);
  await file.delete();
}

class StartPage extends StatelessWidget {
  const StartPage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  Widget build(BuildContext context) {
    Future<String> config = _localRead('config.json');
    return FutureBuilder<String>(
      future: config,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if(snapshot.hasData){
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => DecryptPage(title: 'Decrypt Data', config: '${snapshot.data}', failed: false)),
              (route) => false,
            );
          });
        }
        if(snapshot.hasError){
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SetupPage(title: 'Create Password')),
              (route) => false,
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

class DecryptPage extends StatelessWidget {
  const DecryptPage({Key? key, required this.title, required this.config, required this.failed}) : super(key: key);
  final String title;
  final String config;
  final bool failed;
  @override
  Widget build(BuildContext context) {
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShredPage(title: 'Shred Data')),
                );
              },
              child: const Text('Shred Data'),
            ),
          ],
        ),
      ),
    );
  }
}

class StartForm extends StatefulWidget {
  const StartForm({super.key});
  @override
  StartFormState createState() {
    return StartFormState();
  }
}

class ShredForm extends StatefulWidget {
  const ShredForm({super.key});
  @override
  ShredFormState createState() {
    return ShredFormState();
  }
}

class DecryptForm extends StatefulWidget {
  const DecryptForm({super.key, required this.config});
  final String config;
  @override
  DecryptFormState createState() {
    return DecryptFormState();
  }
}

List<int> getNonce() {
  var rng = Random.secure();
  List<int> nonce = [];
  for(int i = 0;i<8;i++){
    nonce.add(rng.nextInt(256));
  }
  return nonce;
}

Future<SecretKey> deriveKeyCompute(Tuple3<Pbkdf2, SecretKey, List<int>> args) async {
  return await args.item1.deriveKey(secretKey: args.item2, nonce: args.item3);
}

Future<SecretKey> getKey(Pbkdf2 keyDerivator, String password, List<int> nonce) async {
    return await compute(
      deriveKeyCompute,
      Tuple3<Pbkdf2, SecretKey, List<int>>(keyDerivator, SecretKey(password.codeUnits), nonce),
    );
}

Future<SecretBox> encryptCompute(Tuple5<AesGcm, List<int>, SecretKey, List<int>, List<int>> args) async {
  return await args.item1.encrypt(
    args.item2,
    secretKey: args.item3,
    nonce: args.item4,
    aad: args.item5,
  );
}

Future<List<int>> decryptCompute(Tuple4<AesGcm, SecretBox, SecretKey, List<int>> args) async {
  return await args.item1.decrypt(
    args.item2,
    secretKey: args.item3,
    aad: args.item4,
  );
}

Function eq = const ListEquality().equals;

class ReadPage extends StatelessWidget {
  const ReadPage({Key? key, required this.title, required this.password, required this.nonce, required this.iterations, required this.config}) : super(key: key);
  final String password;
  final List<int> nonce;
  final int iterations;
  final String title;
  final String config;
  Future<int> encrypt() async {
    final keyDerivator = Pbkdf2(
      macAlgorithm: Hmac.sha512(),
      iterations: iterations,
      bits: 256,
    );
    SecretKey key = await getKey(keyDerivator, password, nonce);
    final algorithm = AesGcm.with256bits();
    List<int> data = await _localReadAsBytes('data');
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
    Future<int> task = encrypt();
    return FutureBuilder<int>(
      future: task,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        if(snapshot.hasData){
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage(title: 'Home')),
              (route) => false,
            );
          });
        }
        if(snapshot.hasError){
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => DecryptPage(config: config, title: 'Decrypt Data', failed: true)),
              (route) => false,
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

class WritePage extends StatelessWidget {
  const WritePage({Key? key, required this.title, required this.password, required this.nonce, required this.data, required this.iterations}) : super(key: key);
  final String password;
  final List<int> nonce;
  final List<int> data;
  final int iterations;
  final String title;
  Future<int> encrypt() async {
    final keyDerivator = Pbkdf2(
      macAlgorithm: Hmac.sha512(),
      iterations: iterations,
      bits: 256,
    );
    SecretKey key = await getKey(keyDerivator, password, nonce);
    final algorithm = AesGcm.with256bits();
    final encNonce = algorithm.newNonce();
    final Map<String, dynamic> config = Map.fromIterables(['nonce', 'iterations'], [nonce, iterations]);
    await _localWrite('config.json', jsonEncode(config));
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
    await _localWriteAsBytes('data', dataToWrite);
    return 0;
  }
  @override
  Widget build(BuildContext context) {
    Future<int> task = encrypt();
    return FutureBuilder<int>(
      future: task,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        if(snapshot.hasData){
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const StartPage(title: 'Working')),
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

class StartFormState extends State<StartForm> {
  final _formKey = GlobalKey<FormState>();
  final pwController = TextEditingController();
  final roundsController = TextEditingController(text: '120000');
  @override
  void dispose() {
    pwController.dispose();
    roundsController.dispose();
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
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Text('PBKDF2 iterations:'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TextFormField(
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
              ),
              controller: roundsController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty || int.tryParse(value) == null || int.tryParse(value)! < 1) {
                  return 'Please enter an integer greater than zero';
                }
                return null;
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WritePage(title: 'Working',
                      password: pwController.text,
                      nonce: getNonce(),
                      data: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
                      iterations: int.tryParse(roundsController.text) ?? 120000,
                    ),
                  ),
                  (route) => false,
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
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReadPage(
                      title: 'Working',
                      password: pwController.text,
                      nonce: confJSON['nonce'].cast<int>(),
                      iterations: confJSON['iterations'] as int,
                      config: widget.config,
                    ),
                  ),
                  (route) => false,
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

class ShredFormState extends State<ShredForm> {
  final _formKey = GlobalKey<FormState>();
  Future<void> formSave(String? method, VoidCallback onSuccess) async {
    await _localShredFile('config.json', method);
    await _localShredFile('data', method);
    onSuccess.call();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: DropdownButtonFormField<String>(
              value: 'U.S. DoD 5220.22-M (ECE)',
              onChanged: (String? _) {},
              onSaved: (String? value) {
                formSave(value, () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const StartPage(title: 'Working')),
                    (route) => false,
                  );
                });
              },
              items: <String>['U.S. DoD 5220.22-M (ECE)', 'U.S. DoD 5220.22-M (E)', 'Bruce Schneier\'s Algorithm'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _formKey.currentState?.save();
            },
            child: const Text('Shred'),
          ),
        ],
      ),
    );
  }
}

class SetupPage extends StatelessWidget {
  const SetupPage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            StartForm(),
          ],
        ),
      ),
    );
  }
}

class ShredPage extends StatelessWidget {
  const ShredPage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            ShredForm(),
          ],
        ),
      ),
    );
  }
}
