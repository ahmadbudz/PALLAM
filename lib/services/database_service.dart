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
    if (_db != null) {
      return _db!;
    } else {
      _db = await getDatabase();
      return _db!;
    }
  }

  Future<Database> getDatabase() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "pallam_db.db");
    final database = await openDatabase(
      databasePath,
      onCreate: (db, version) {
        db.execute('''
        CREATE TABLE $_chatsTableName (
          $_chatsChatIdColumnName    INTEGER PRIMARY KEY AUTOINCREMENT,
          $_chatsChatNameColumnName  TEXT NOT NULL DEFAULT 'New Chat',
          $_chatsCreatedAtColumnName TEXT DEFAULT CURRENT_TIMESTAMP,
          $_chatsUpdatedAtColumnName TEXT DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE $_messagesTableName (
          $_messagesMessageIdColumnName INTEGER PRIMARY KEY AUTOINCREMENT,
          $_messagesChatIdColumnName    INTEGER NOT NULL,
          $_messagesSenderColumnName   TEXT NOT NULL,
          $_messagesContentColumnName  TEXT NOT NULL,
          $_messagesTimestampColumnName TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY ($_messagesChatIdColumnName) REFERENCES $_chatsTableName($_chatsChatIdColumnName) ON DELETE CASCADE
        );
        ''');
      },
      onConfigure: (db) {
        db.execute('PRAGMA foreign_keys = ON;');
      },
    );
    return database;
  }

  Future<void> insertQuestionAndAnswer(String question, int chatId) async {
    final db = await database;
    String answer = "alllooooooo"; // Temporary

    await db.transaction((txn) async {
      try {
        // 1. Handle chat creation if needed
        if (chatId == 0) {
          chatId = await txn.insert(_chatsTableName, {
            _chatsChatNameColumnName:
                'test', //TODO: how can we generate chat names?
          });
        }

        // 2. Insert user question
        await txn.insert(_messagesTableName, {
          _messagesChatIdColumnName: chatId,
          _messagesSenderColumnName: 'user',
          _messagesContentColumnName: question,
          _messagesTimestampColumnName: DateTime.now().toUtc().toString(),
        });

        // 3. Get answer from LLM (HTTP call should be OUTSIDE transaction)
        // answer = await fetchLLMAnswer(question); // TODO: Implement this in the future

        // 4. Insert bot response
        await txn.insert(_messagesTableName, {
          _messagesChatIdColumnName: chatId,
          _messagesSenderColumnName: 'LLM', // Keep consistent naming
          _messagesContentColumnName: answer,
          _messagesTimestampColumnName: DateTime.now().toUtc().toString(),
        });
      } catch (e) {
        print('Error in transaction: $e');
        rethrow;
      }
    });
  }

  Future<List<Chats>> getChats() async {
    final db = await database;
    final data = await db.query(_chatsTableName);
    List<Chats> chats =
        data
            .map(
              (e) => Chats(
                chat_id: e[_chatsChatIdColumnName] as int,
                chat_name: e[_chatsChatNameColumnName] as String,
                created_at: e[_chatsCreatedAtColumnName] as String,
                updated_at: e[_chatsUpdatedAtColumnName] as String,
              ),
            )
            .toList();
    return chats;
  }

  void renameChat(int chatId, String newChatName) async {
    final db = await database;
    await db.update(
      _chatsTableName,
      {_chatsChatNameColumnName: newChatName},
      where: '$_chatsChatIdColumnName = ?',
      whereArgs: [chatId],
    );
  }

  void deleteChat(int chatId) async {
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
    List<Messages> messages =
        data
            .map(
              (e) => Messages(
                message_id: e[_messagesMessageIdColumnName] as int,
                chat_id: e[_messagesChatIdColumnName] as int,
                sender: e[_messagesSenderColumnName] as String,
                content: e[_messagesContentColumnName] as String,
                timestamp: e[_messagesTimestampColumnName] as String,
              ),
            )
            .toList();
    return messages;
  }

  Future<void> editQuestion(int chatId, int messageId, String newQuestion) async {
  final db = await database;

  await db.transaction((txn) async {
    try {
      // 1. Update the user's question
      await txn.update(
        _messagesTableName,
        {_messagesContentColumnName: newQuestion},
        where: '$_messagesMessageIdColumnName = ?',
        whereArgs: [messageId],
      );

      // Generate new answer
      // answer = await fetchLLMAnswer(question); // TODO: Implement this in the future
      String answer = "allloo"; // Temporary

      // 5. Update LLM's response
      int botMessageId = messageId++;
      await txn.update(
        _messagesTableName,
        {
          _messagesContentColumnName: answer,
          _messagesTimestampColumnName: DateTime.now().toUtc().toString(),
        },
        where: '$_messagesMessageIdColumnName = ?',
        whereArgs: [botMessageId],
      );
    } catch (e) {
      print('Error editing question: $e');
      rethrow;
    }
  });
}

}
