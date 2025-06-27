// lib/widgets/loading_bubble.dart
import 'package:flutter/material.dart';

class LoadingBubble extends StatelessWidget {
  final bool isUser;
  const LoadingBubble({ Key? key, this.isUser = false }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = isUser ? Colors.blueAccent : Colors.grey.shade200;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2,
            color: Colors.green,),
        ),
      ),
    );
  }
}
