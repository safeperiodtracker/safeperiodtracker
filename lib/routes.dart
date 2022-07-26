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

import 'package:flutter/widgets.dart';
import 'package:periodtracker/screens/homepage.dart';
import 'package:periodtracker/screens/startpage.dart';
import 'package:periodtracker/screens/decryptpage.dart';
import 'package:periodtracker/screens/setuppage.dart';
import 'package:periodtracker/screens/shredpage.dart';
import 'package:periodtracker/screens/utility/writepage.dart';
import 'package:periodtracker/screens/utility/readpage.dart';

final Map<String, WidgetBuilder> routes = <String, WidgetBuilder>{
  '/': (BuildContext context) => const StartPage(title: 'Working'),
  '/DecryptPage': (BuildContext context) => const DecryptPage(),
  '/SetupPage': (BuildContext context) => const SetupPage(),
  '/ShredPage': (BuildContext context) => const ShredPage(),
  '/WritePage': (BuildContext context) => const WritePage(),
  '/ReadPage': (BuildContext context) => const ReadPage(),
  '/HomePage': (BuildContext context) => const HomePage(),
};
