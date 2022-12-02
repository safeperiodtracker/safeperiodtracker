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
import 'package:periodtracker/screens/arguments/setuppage.dart';
import 'package:periodtracker/screens/arguments/writepage.dart';
import 'package:periodtracker/utilities.dart';

class StartForm extends StatefulWidget {
  const StartForm({super.key});

  @override
  StartFormState createState() {
    return StartFormState();
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
                final writeargs = WritePageArguments(
                  'Working',
                  pwController.text,
                  getNonce(),
                  const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
                  int.tryParse(roundsController.text) ?? 120000,
                  true,
                  2,
                  true,
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/WritePage',
                  (route) => false,
                  arguments: writeargs,
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

class SetupPage extends StatelessWidget {
  const SetupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context){
    final title = (ModalRoute.of(context)!.settings.arguments as SetupPageArguments).title;
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
