class Messages {
  final int message_id, chat_id;
  final String sender, content, timestamp;

  Messages({
    required this.message_id,
    required this.chat_id,
    required this.sender,
    required this.content,
    required this.timestamp
  });

}