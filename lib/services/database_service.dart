import 'package:chatbot_app/models/chats.dart';
import 'package:chatbot_app/models/messages.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class databaseService {
  static Database? _db;

  static final databaseService instance = databaseService._constructor();

  final String _chatsTableName = "chats";
  final String _chatsChatIdColumnName = "chat_id";
  final String _chatsChatNameColumnName = "chat_name";
  final String _chatsCreatedAtColumnName = "created_at";
  final String _chatsUpdatedAtColumnName = "updated_at";

  final String _messagesTableName = "messages";
  final String _messagesMessageIdColumnName = "message_id";
  final String _messagesChatIdColumnName = "chat_id";
  final String _messagesSenderColumnName = "sender"; // user or bot
  final String _messagesContentColumnName = "content";
  final String _messagesTimestampColumnName = "timestamp";

  databaseService._constructor();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "pallam_db.db");
    return openDatabase(
      databasePath,
      version: 1, // <-- Specify version when using onCreate
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        // Create chats table
        await db.execute('''
          CREATE TABLE $_chatsTableName (
            $_chatsChatIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
            $_chatsChatNameColumnName TEXT NOT NULL DEFAULT 'New Chat',
            $_chatsCreatedAtColumnName TEXT DEFAULT CURRENT_TIMESTAMP,
            $_chatsUpdatedAtColumnName TEXT DEFAULT CURRENT_TIMESTAMP
          );
        ''');
        // Create messages table
        await db.execute('''
          CREATE TABLE $_messagesTableName (
            $_messagesMessageIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
            $_messagesChatIdColumnName INTEGER NOT NULL,
            $_messagesSenderColumnName TEXT NOT NULL,
            $_messagesContentColumnName TEXT NOT NULL,
            $_messagesTimestampColumnName TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY ($_messagesChatIdColumnName) REFERENCES $_chatsTableName($_chatsChatIdColumnName) ON DELETE CASCADE
          );
        ''');
      },
    );
  }

  Future<int> insertQuestionAndAnswer(
      String question, int chatId, String answer) async {
    final db = await database;

    return await db.transaction<int>((txn) async {
      if (chatId == 0) {
        chatId = await txn.insert(
          _chatsTableName,
          {_chatsChatNameColumnName: 'New Chat'},
        );
      }

      await txn.insert(_messagesTableName, {
        _messagesChatIdColumnName: chatId,
        _messagesSenderColumnName: 'user',
        _messagesContentColumnName: question,
        _messagesTimestampColumnName: DateTime.now().toUtc().toString(),
      });

      await txn.insert(_messagesTableName, {
        _messagesChatIdColumnName: chatId,
        _messagesSenderColumnName: 'LLM',
        _messagesContentColumnName: answer,
        _messagesTimestampColumnName: DateTime.now().toUtc().toString(),
      });

      return chatId;
    });
  }

/// Creates a new conversation/chat with the given [chatName] and returns its generated ID.
Future<int> createChat(String chatName) async {
  final db = await database;
  final newId = await db.insert(
    _chatsTableName,
    {
      _chatsChatNameColumnName: chatName,
      // created_at and updated_at will default to CURRENT_TIMESTAMP
    },
  );
  return newId;
}


  Future<List<Chats>> getChats() async {
    final db = await database;
    final data = await db.query(_chatsTableName);
    return data.map((e) => Chats(
          chat_id: e[_chatsChatIdColumnName] as int,
          chat_name: e[_chatsChatNameColumnName] as String,
          created_at: e[_chatsCreatedAtColumnName] as String,
          updated_at: e[_chatsUpdatedAtColumnName] as String,
        )).toList();
  }

  Future<void> renameChat(int chatId, String newChatName) async {
    final db = await database;
    await db.update(
      _chatsTableName,
      {_chatsChatNameColumnName: newChatName},
      where: '$_chatsChatIdColumnName = ?',
      whereArgs: [chatId],
    );
  }

  Future<void> deleteChat(int chatId) async {
    final db = await database;
    await db.delete(
      _chatsTableName,
      where: '$_chatsChatIdColumnName = ?',
      whereArgs: [chatId],
    );
  }

  Future<List<Messages>> getMessages() async {
    final db = await database;
    final data = await db.query(_messagesTableName);
    return data.map((e) => Messages(
          message_id: e[_messagesMessageIdColumnName] as int,
          chat_id: e[_messagesChatIdColumnName] as int,
          sender: e[_messagesSenderColumnName] as String,
          content: e[_messagesContentColumnName] as String,
          timestamp: e[_messagesTimestampColumnName] as String,
        )).toList();
  }

  Future<void> editQuestion(
      int chatId, int messageId, String newQuestion) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        _messagesTableName,
        {_messagesContentColumnName: newQuestion},
        where: '$_messagesMessageIdColumnName = ?',
        whereArgs: [messageId],
      );

      // Insert updated LLM answer if needed
      // TODO: implement LLM fetch and update
    });
  }
}
