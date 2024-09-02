import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';
import 'package:powersync/src/database/native/native_powersync_database.dart';
import 'package:path/path.dart';
import 'package:powersync/sqlite_async.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/open.dart' as sqlite_open;

final sqliteBinPath = const String.fromEnvironment("SQLITE_BIN").trim();

const schema = Schema([
  Table('users', [
    Column.text('email'),
    Column.text('hashed_password'),
    Column.text('confirmed_at'),
    Column.text('first_name'),
    Column.text('last_name'),
    Column.text('inserted_at'),
    Column.text('updated_at')
  ]),
]);

class TestOpenFactory extends PowerSyncOpenFactory {
  TestOpenFactory({required super.path});

  @override
  CommonDatabase open(SqliteOpenOptions options) {
    // if (sqliteBinPath.isEmpty) {
    //   throw "SQLITE_BIN must be set and non-blank";
    // }
    // print(sqliteBinPath);

    sqlite_open.open.overrideFor(sqlite_open.OperatingSystem.macOS, () {
      return DynamicLibrary.open('libsqlite3.dylib');
    });
    return super.open(options);
  }
}

void main() {
  group("debug powersync", () {
    test("teardown powersync", () async {
      final basepath = await Directory.systemTemp.createTemp("example");
      final dbPath = join(basepath.path, 'test_database.db');
      final openFactory = TestOpenFactory(path: dbPath);
      final db = SqliteDatabase.withFactory(openFactory);
      final powersyncDb =
          PowerSyncDatabaseImpl.withDatabase(schema: schema, database: db);

      print("tearing down");
      await powersyncDb.close();
      print("closed powersync");
    });
  });
}
