import 'package:flutter/material.dart';

void main() {
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
  final TextEditingController _controller = TextEditingController();
  final List<String> _userMessages = [];
  final List<String> _conversations = ['محادثة 1 (اختبار)', 'محادثة 2 (اختبار)'];

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _userMessages.add(text);
      _controller.clear();
    });
  }

  void _renameConversation(int index) async {
    final TextEditingController renameController =
        TextEditingController(text: _conversations[index]);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Conversation'),
          content: TextField(
            controller: renameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter new name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, renameController.text.trim()),
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _conversations[index] = newName;
      });
    }
  }

  void _deleteConversation(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _conversations.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        backgroundColor: const Color(0xFF597157),
        title: const Text(
          'ℙ𝔸𝕃𝕃𝔸𝕄',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF597157),
              ),
              child: Text(
                'Previous Conversations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (int i = 0; i < _conversations.length; i++)
              ListTile(
                title: Text(_conversations[i]),
                leading: const Icon(Icons.history),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'rename') {
                      _renameConversation(i);
                    } else if (value == 'delete') {
                      _deleteConversation(i);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(value: 'rename', child: Text('Rename')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Image.asset(
                'images/palestine.png',
                height: 400, 
                fit: BoxFit.cover, 
              ),
            ),
          ),
          Column(
            children: [
              // Chat messages list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: _userMessages.length,
                  itemBuilder: (context, index) {
                    final reversedIndex = _userMessages.length - 1 - index;
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: const Color(0xFF597157),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          _userMessages[reversedIndex],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Input field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF597157),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'ما الذي يدور في ذهنك حول جغرافية فلسطين؟',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _handleSend,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
