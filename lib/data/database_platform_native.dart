import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

DatabaseFactory get platformDatabaseFactory => databaseFactory;

Future<String> platformDatabasePath() async =>
    p.join(await getDatabasesPath(), 'roleplay.sqlite3');
