import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'services/chatservice.dart';
import 'services/database_service.dart';
import 'models/chats.dart';
import 'models/messages.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PALLAM Chatbot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: const Color(0xFF597157)),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _currentChatId = 0;
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final List<String> _userMessages = [];
  final List<String> _botMessages = [];
  List<Chats> _conversations = [];

  bool _waitingForResponse = false;  // variable to check the state of the response 

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final chats = await databaseService.instance.getChats();
    setState(() {
      _conversations = chats;
    });
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _userMessages.add(text);
      _controller.clear();
      _waitingForResponse = true;  // for disable the input until return the respnse 
    });

    try {
      final botReply = await _chatService.getResponse(text);
      final updatedChatId = await databaseService.instance
          .insertQuestionAndAnswer(text, _currentChatId, botReply);

      setState(() {
        _currentChatId = updatedChatId;
        _botMessages.add(botReply);
        _waitingForResponse = false;  //  re-enable the input
      });
    } catch (e) {
      setState(() {
        _botMessages.add('⚠️ حدث خطأ في الاتصال بالنموذج.');
        _waitingForResponse = false; 
      });
      print('Error from model: $e');
    }
  }

  Future<void> _createNewConversation() async {
    final newId = await databaseService.instance.createChat('New Chat');
    await _loadConversations();
    setState(() {
      _currentChatId = newId;
      _userMessages.clear();
      _botMessages.clear();
    });
    Navigator.pop(context);
  }

  Future<void> _selectConversation(int index) async {
    final chat = _conversations[index];
    setState(() {
      _currentChatId = chat.chat_id;
      _userMessages.clear();
      _botMessages.clear();
    });

    final messages = await databaseService.instance.getMessages();
    for (var msg in messages.where((m) => m.chat_id == _currentChatId)) {
      if (msg.sender == 'user') {
        _userMessages.add(msg.content);
      } else {
        _botMessages.add(msg.content);
      }
    }
    Navigator.pop(context);
  }

  Future<void> _renameConversation(int index) async {
    final chats = await databaseService.instance.getChats();
    final id = chats[index].chat_id;
    final controller = TextEditingController(text: chats[index].chat_name);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Enter new name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Rename')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await databaseService.instance.renameChat(id, newName);
      await _loadConversations();
    }
  }

  Future<void> _deleteConversation(int index) async {
    final chats = await databaseService.instance.getChats();
    final id = chats[index].chat_id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await databaseService.instance.deleteChat(id);
      await _loadConversations();
      if (_currentChatId == id) {
        setState(() { _currentChatId = 0; _userMessages.clear(); _botMessages.clear(); });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        backgroundColor: const Color(0xFF597157),
        title: const Text(
          'ℙ𝔸𝕃𝕃𝔸𝕄',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF597157)),
            child: Text('Conversations', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          ListTile(leading: const Icon(Icons.add), title: const Text('New Conversation'), onTap: _createNewConversation),
          const Divider(),
          for (int i = 0; i < _conversations.length; i++)
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(_conversations[i].chat_name),
              trailing: PopupMenuButton<String>(
                onSelected: (val) { if (val=='rename') _renameConversation(i); else if(val=='delete') _deleteConversation(i); },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
              onTap: () => _selectConversation(i),
            ),
        ]),
      ),
      backgroundColor: Colors.white,
      body: Stack(children: [
        Positioned.fill(
          child: Center(child: Image.asset('images/palestine.png', height: 400, fit: BoxFit.cover)),
        ),
        Column(children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: false,
              itemCount: _userMessages.length + _botMessages.length,
              itemBuilder: (ctx, index) {
              final isUser = index.isEven;
              final msgIndex = index ~/ 2;
              final message = isUser
                  ? _userMessages[msgIndex]
                  : (_botMessages.length > msgIndex ? _botMessages[msgIndex] : '');

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF597157) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 16,
                          height: 1.3,
                        ),
                        textAlign: isUser ? TextAlign.right : TextAlign.left,
                      ),
                    ),

                    if (!isUser)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: message));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied to clipboard!')),
                          );
                        },
                      ),
                  ],
                ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFF597157), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_waitingForResponse, //disable typing while waiting
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(hintText: 'ما الذي يدور في ذهنك حول جغرافية فلسطين؟', hintStyle: TextStyle(color: Colors.white70), border: InputBorder.none),
                   onSubmitted: !_waitingForResponse ? (_) => _handleSend() : null, // disable enter-send
                ),
              ),
              IconButton(
                icon: _waitingForResponse
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _waitingForResponse ? null : _handleSend, // disable send button
              ),
            ]),
          ),
        ]),
      ]),
    );
  }
}