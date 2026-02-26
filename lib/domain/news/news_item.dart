import '../funcs/parseFuncs.dart';

class NewsPost {
  final int postId;
  final int groupId;
  final String groupName;
  final int userId;
  final String userName;
  final String title;
  final String message;
  final DateTime dateAdd;
  final String groupLogoUrl;

  const NewsPost({
    required this.postId,
    required this.groupId,
    required this.groupName,
    required this.userId,
    required this.userName,
    required this.title,
    required this.message,
    required this.dateAdd,
    required this.groupLogoUrl,
  });

  factory NewsPost.fromAPI(Map<String, dynamic> json){
    final int postId = toInt(json['post_id']);
    final int groupId = toInt(json['group_id']);
    final String groupName = toStr(json['group_name']);
    final int userId = toInt(json['user_id']);
    final String userName = toStr(json['user_name']);
    final String title = toStr(json['title']);
    final String message = toStr(json['message']);
    final DateTime dateAdd = parseDt(json['date_add']);
    final String groupLogoUrl = toStr(json['group_logo_url']);
    return NewsPost(postId: postId,
        groupId: groupId,
        groupName: groupName,
        userId: userId,
        userName: userName,
        title: title,
        message: message,
        dateAdd: dateAdd,
        groupLogoUrl: groupLogoUrl
    );
  }
}

