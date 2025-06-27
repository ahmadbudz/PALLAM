import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/chatservice.dart';
import 'services/database_service.dart';
import 'models/chats.dart';
import 'models/messages.dart';
import 'widgets/typewriter_text.dart';
import 'widgets/loading_bubble.dart';

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
  final List<String?> _botMessages = [];      // allow null for loading placeholder
  List<Chats> _conversations = [];
  int? _animatingIndex;                       // which bubble animates
  bool _waitingForResponse = false;
  bool _animating = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final chats = await databaseService.instance.getChats();
    setState(() {
      _conversations = chats;
      _animatingIndex = null; // no animation when loading history
    });
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _userMessages.add(text);
      _controller.clear();
      _waitingForResponse = true;
      _botMessages.add(null);   // show spinner
    });

    try {
      final botReply = await _chatService.getResponse(text);
      final updatedChatId = await databaseService.instance
          .insertQuestionAndAnswer(text, _currentChatId, botReply);

      setState(() {
        _currentChatId = updatedChatId;
        _botMessages[_botMessages.length - 1] = botReply;
        _animatingIndex = _botMessages.length - 1; // animate this one
        _animating = true; 
        _waitingForResponse   = false; 
      });
    } catch (e) {
      setState(() {
        _botMessages[_botMessages.length - 1] =
            '⚠️ حدث خطأ في الاتصال بالنموذج.';
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
      _animatingIndex = null; // no animation on old messages
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
    backgroundColor: const Color(0xFF597157),              // dialog bg
    title: const Text(
      'Rename Conversation',
      style: TextStyle(color: Colors.white),               // title text
    ),
    content: TextField(
      controller: controller,
      decoration: const InputDecoration(
        hintText: 'Enter new name',
        hintStyle: TextStyle(color: Colors.white70),        // hint color
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),    // underline
        ),
      ),
      style: const TextStyle(color: Colors.white),          // input text
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel', style: TextStyle(color: Colors.white)),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,                     // button bg
        ),
        onPressed: () => Navigator.pop(context, controller.text.trim()),
        child: const Text(
          'Rename',
          style: TextStyle(color: Color(0xFF597157)),       // button text
        ),
      ),
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
    backgroundColor: const Color(0xFF597157),
    title: const Text(
      'Delete Conversation',
      style: TextStyle(color: Colors.white),
    ),
    content: const Text(
      'Are you sure you want to delete this conversation?',
      style: TextStyle(color: Colors.white70),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text(
          'Cancel',
          style: TextStyle(color: Colors.white),
        ),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
        ),
        onPressed: () => Navigator.pop(context, true),
        child: const Text(
          'Delete',
          style: TextStyle(color: Color(0xFF597157)),
        ),
      ),
    ],
  ),
);

    if (confirmed == true) {
      await databaseService.instance.deleteChat(id);
      await _loadConversations();
      if (_currentChatId == id) {
        setState(() {
          _currentChatId = 0;
          _userMessages.clear();
          _botMessages.clear();
        });
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
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF597157)),
            child: Text('Conversations',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New Conversation'),
              onTap: _createNewConversation),
          const Divider(),
          for (int i = 0; i < _conversations.length; i++)
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(_conversations[i].chat_name),
              trailing: PopupMenuButton<String>(
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (val) {   
                if (val == 'rename') _renameConversation(i);
                   else if (val == 'delete') _deleteConversation(i);},
              itemBuilder: (ctx) => [
                PopupMenuItem<String>(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit, color: Theme.of(ctx).primaryColor),
                    title: Text(
                      'Rename',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(ctx).primaryColor,
                      ),
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.redAccent),
                    title: Text(
                      'Delete',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ),

              onTap: () => _selectConversation(i),
            ),
        ]),
      ),
      backgroundColor: Colors.white,
      body: Stack(children: [
        Positioned.fill(
            child: Center(
                child: Image.asset('images/palestine.png',
                    height: 400, fit: BoxFit.cover))),
        Column(children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: false,
              itemCount: _userMessages.length + _botMessages.length,
              itemBuilder: (ctx, index) {
                final isUser = index.isEven;
                final msgIndex = index ~/ 2;

                if (!isUser) {
                  final content = _botMessages[msgIndex];
                  if (content == null) {
                    return LoadingBubble(isUser: false);
                  }
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin:
                              const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          constraints:
                              const BoxConstraints(maxWidth: 300),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: msgIndex == _animatingIndex
                              ? TypewriterText(
                                  text: content,
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16),
                                      onComplete: () {
                                        setState(() {
                                          _animating = false;
                                            });
                                       },
                                )
                              : Text(
                                  content,
                                  style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16),
                                ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.copy,
                              size: 20, color: Colors.grey),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: content));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('Copied to clipboard!'),
                            ));
                          },
                        ),
                      ],
                    ),
                  );
                }

                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints:
                        const BoxConstraints(maxWidth: 300),
                    decoration: BoxDecoration(
                      color: const Color(0xFF597157),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _userMessages[msgIndex],
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
                color: Color(0xFF597157),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_waitingForResponse  && !_animating,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: _waitingForResponse
                        ? 'جاري الانتظار…'
                        : 'ما الذي يدور في ذهنك حول جغرافية فلسطين؟',
                    hintStyle:
                        const TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  onSubmitted: !_waitingForResponse
                      ? (_) => _handleSend()
                      : null,
                ),
              ),
              IconButton(
                icon: (_waitingForResponse || _animating)
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: (_waitingForResponse || _animating) ? null : _handleSend,
              ),
            ]),
          ),
        ]),
      ]),
    );
  }
}