import 'package:sqflite_common/sqlite_api.dart';

import '../models/chat_models.dart';
import 'database_platform.dart';

class AppDatabase {
  AppDatabase._(this._database);

  final Database _database;

  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final selectedFactory = factory ?? platformDatabaseFactory;
    final databasePath = path ?? await platformDatabasePath();
    final database = await selectedFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, _) async => _createSchema(db),
        onOpen: (db) async => _seedSingletons(db),
      ),
    );
    return AppDatabase._(database);
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT NOT NULL CHECK(role IN ('user', 'assistant')),
        content TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE memory (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        summary TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('''
      CREATE TABLE relationship (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        familiarity INTEGER NOT NULL DEFAULT 0 CHECK(familiarity BETWEEN 0 AND 100),
        trust INTEGER NOT NULL DEFAULT 0 CHECK(trust BETWEEN 0 AND 100),
        affection INTEGER NOT NULL DEFAULT 0 CHECK(affection BETWEEN 0 AND 100),
        grudge INTEGER NOT NULL DEFAULT 0 CHECK(grudge BETWEEN 0 AND 100),
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await _seedSingletons(db);
  }

  static Future<void> _seedSingletons(Database db) async {
    await db.insert('memory', {
      'id': 1,
      'summary': '',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('relationship', {
      'id': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<ChatMessage>> allMessages() async {
    final rows = await _database.query('messages', orderBy: 'id ASC');
    return rows.map(_messageFromRow).toList();
  }

  Future<List<ChatMessage>> recentMessages({int turns = 20}) async {
    final rows = await _database.rawQuery(
      '''
      SELECT id, role, content FROM (
        SELECT id, role, content FROM messages ORDER BY id DESC LIMIT ?
      ) ORDER BY id ASC
      ''',
      [turns * 2],
    );
    return rows.map(_messageFromRow).toList();
  }

  Future<List<ChatMessage>> oldestMessages(int limit) async {
    final rows = await _database.query(
      'messages',
      orderBy: 'id ASC',
      limit: limit,
    );
    return rows.map(_messageFromRow).toList();
  }

  Future<int> messageCount() async {
    final result = await _database.rawQuery(
      'SELECT COUNT(*) AS count FROM messages',
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<void> addTurn(String user, String assistant) async {
    await _database.transaction((txn) async {
      await txn.insert('messages', {'role': 'user', 'content': user});
      await txn.insert('messages', {'role': 'assistant', 'content': assistant});
    });
  }

  Future<String> memory() async {
    final rows = await _database.query(
      'memory',
      columns: ['summary'],
      where: 'id = 1',
      limit: 1,
    );
    return rows.single['summary'] as String;
  }

  Future<RelationshipState> relationship() async {
    final rows = await _database.query(
      'relationship',
      where: 'id = 1',
      limit: 1,
    );
    final row = rows.single;
    return RelationshipState(
      familiarity: row['familiarity'] as int,
      trust: row['trust'] as int,
      affection: row['affection'] as int,
      grudge: row['grudge'] as int,
    );
  }

  Future<void> setRelationship(RelationshipState value) async {
    await _database.update('relationship', {
      'familiarity': value.familiarity,
      'trust': value.trust,
      'affection': value.affection,
      'grudge': value.grudge,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id = 1');
  }

  Future<void> replaceMemory(
    String summary,
    List<ChatMessage> deletedMessages,
  ) async {
    if (deletedMessages.isEmpty) return;
    await _database.transaction((txn) async {
      await txn.update('memory', {
        'summary': summary,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, where: 'id = 1');
      final placeholders = List.filled(deletedMessages.length, '?').join(',');
      await txn.delete(
        'messages',
        where: 'id IN ($placeholders)',
        whereArgs: deletedMessages.map((message) => message.id).toList(),
      );
    });
  }

  Future<void> close() => _database.close();

  static ChatMessage _messageFromRow(Map<String, Object?> row) {
    return ChatMessage(
      id: row['id'] as int,
      role: MessageRole.values.byName(row['role'] as String),
      content: row['content'] as String,
    );
  }
}
