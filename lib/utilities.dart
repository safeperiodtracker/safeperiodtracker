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

import 'dart:math';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cryptography/cryptography.dart';
import 'package:tuple/tuple.dart';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> localFile(String filename) async {
  final path = await _localPath;
  return File('$path/$filename');
}

Future<String> localRead(String filename) async {
  final file = await localFile(filename);
  return await file.readAsString();
}

Future<void> localWrite(String filename, String contents) async {
  final file = await localFile(filename);
  await file.writeAsString(contents);
}

Future<List<int>> localReadAsBytes(String filename) async {
  final file = await localFile(filename);
  return await file.readAsBytes();
}

Future<void> localWriteAsBytes(String filename, List<int> contents) async {
  final file = await localFile(filename);
  await file.writeAsBytes(contents);
}

Future<void> localSchneier(File file, int length) async {
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

Future<void> localDoDE(File file, int length) async{
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

Future<void> localDoDECE(File file, int length) async {
  await localDoDE(file, length);
  var rng = Random.secure();
  List<int> write = [];
  for(int i = 0;i<length;i++){
    write.add(rng.nextInt(256));
  }
  await file.writeAsBytes(write);
  await localDoDE(file, length);
}

Future<void> localShredFile(String filename, String? method) async {
  final file = await localFile(filename);
  final length = await file.length();
  switch(method) {
    case 'Bruce Schneier\'s Algorithm': {
      await localSchneier(file, length);
    }
    break;
    case 'U.S. DoD 5220.22-M (E)': {
      await localDoDE(file, length);
    }
    break;
    case 'U.S. DoD 5220.22-M (ECE)': {
      await localDoDECE(file, length);
    }
    break;
    default: {
      await localDoDECE(file, length);
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
