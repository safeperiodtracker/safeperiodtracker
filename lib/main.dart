import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/scheduler.dart';
import 'package:tuple/tuple.dart';

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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DecryptPage(title: 'Decrypt Data', config: '${snapshot.data}')),
            );
          });
        }
        if(snapshot.hasError){
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SetupPage(title: 'Create Password')),
            );
          });
        }
        return Center(
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
        );
      },
    );
  }
}

class DecryptPage extends StatelessWidget {
  const DecryptPage({Key? key, required this.title, required this.config}) : super(key: key);
  final String title;
  final String config;
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SetupPage(title: 'Home')),
                );
              },
              child: const Text('Unlock Data'),
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

Future<Tuple2<SecretKey, List<int>>> getKey(Pbkdf2 keyDerivator, String password, List<int> nonce) async {
  return Tuple2<SecretKey, List<int>>(
    await compute(
      deriveKeyCompute,
      Tuple3<Pbkdf2, SecretKey, List<int>>(keyDerivator, SecretKey(password.codeUnits), nonce),
    ),
    nonce,
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
    Tuple2<SecretKey, List<int>> key = await getKey(keyDerivator, password, nonce);
    final algorithm = AesGcm.with256bits();
    final encNonce = algorithm.newNonce();
    final secretBox = await compute(
      encryptCompute,
      Tuple5<AesGcm, List<int>, SecretKey, List<int>, List<int>>(
        algorithm,
        data,
        key.item1,
        encNonce,
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
      ),
    );
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StartPage(title: 'Working')),
            );
          });
        }
        if(snapshot.hasError){
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SetupPage(title: 'Create Password')),
            );
          });
        }
        return Center(
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => WritePage(title: 'Working',
                      password: pwController.text,
                      nonce: getNonce(),
                      data: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
                      iterations: int.tryParse(roundsController.text) ?? 120000),
                  ),
                );
              }
            },
            child: const Text("Submit"),
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
