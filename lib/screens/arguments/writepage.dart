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

class WritePageArguments {
  WritePageArguments(this.title, this.password, this.nonce, this.data, this.iterations, this.loggedOutNotifs, this.loggedOutNotifFreq, this.notifs);
  final String title;
  final String password;
  final List<int> nonce;
  final List<int> data;
  final int iterations;
  final bool loggedOutNotifs;
  final int loggedOutNotifFreq;
  final bool notifs;
}
