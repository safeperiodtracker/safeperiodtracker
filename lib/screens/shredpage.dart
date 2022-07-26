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
import 'package:periodtracker/utilities.dart';
import 'package:periodtracker/screens/arguments/shredpage.dart';

class ShredForm extends StatefulWidget {
  const ShredForm({super.key});

  @override
  ShredFormState createState() {
    return ShredFormState();
  }
}

class ShredFormState extends State<ShredForm> {
  final _formKey = GlobalKey<FormState>();

  Future<void> formSave(String? method, VoidCallback onSuccess) async {
    await localShredFile('config.json', method);
    await localShredFile('data', method);
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
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
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

class ShredPage extends StatelessWidget {
  const ShredPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context){
    final title = (ModalRoute.of(context)!.settings.arguments as ShredPageArguments).title;
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
