import 'package:vsem_mirom/domain/funcs/parseFuncs.dart';

class HelpChatMessageItem {
  final int id;
  final String message;
  final String dateAdd;
  final bool senderAdmin;
  final String author;

  const HelpChatMessageItem({
    required this.id,
    required this.message,
    required this.dateAdd,
    required this.senderAdmin,
    required this.author,
  });

  factory HelpChatMessageItem.fromAPI(Map<String, dynamic> json){
    return HelpChatMessageItem(
        id: toInt(json['message_id']),
        message: toStr(json['message']),
        dateAdd: toStr(json['date_add']),
        senderAdmin: toBool(json['sender_admin']),
        author: toStr(json['author'])
    );
  }
}
