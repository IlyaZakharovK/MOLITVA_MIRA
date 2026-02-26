import '../funcs/parseFuncs.dart';

class Group {
  final int id;
  final String name;
  final String description;
  final int ownerId;
  final DateTime dateAdd;
  final DateTime dateUpdate;
  final String ownerName;
  final String logoUrl;
  final String ownerAvatarUrl;
  final int followersCount;
  final bool isSubscribed;
  final bool isOwner;
  final String invite;
  final bool isClose;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.dateAdd,
    required this.dateUpdate,
    required this.ownerName,
    required this.logoUrl,
    required this.ownerAvatarUrl,
    required this.followersCount,
    required this.isSubscribed,
    required this.isOwner,
    required this.invite,
    required this.isClose,
  });

  factory Group.fromAPI(Map<String, dynamic> json) {
    final id = toInt(json['id']);
    final name = toStr(json['name']);
    final description = toStr(json['description']);
    final ownerId = toInt(json['owner_id']);
    final dateAdd = parseDt(json['date_add']);
    final dateUpdate = parseDt(json['date_update']);
    final ownerName = toStr(json['owner_name']);
    final logoUrl = toStr(json['logo_url']);
    final ownerAvatarUrl = toStr(json['owner_avatar_url']);
    final followersCount = toInt(json['followers_count']);
    final isSubscribed = toBool(json['is_subscribed']);
    final isOwner = toBool(json['is_owner']);
    final invite = toStr(json['is_subscribed']);
    final isClose = toInt(json['is_owner']) == 2;
    return Group(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      dateAdd: dateAdd,
      dateUpdate: dateUpdate,
      ownerName: ownerName,
      logoUrl: logoUrl,
      ownerAvatarUrl: ownerAvatarUrl,
      followersCount: followersCount,
      isSubscribed: isSubscribed,
      isOwner: isOwner,
      invite: invite,
      isClose: isClose,
    );
  }
}

class Comment {
  final int id;
  final int postId;
  final int groupId;
  final int userId;
  final String userName;
  final String message;
  final DateTime dateAdd;
  final String userAvatar;

  const Comment({
    required this.id,
    required this.postId,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.message,
    required this.dateAdd,
    required this.userAvatar,
  });

  factory Comment.fromAPI(Map<String, dynamic> json) {
    final id = toInt(json['id']);
    final postId = toInt(json['post_id']);
    final groupId = toInt(json['group_id']);
    final userId = toInt(json['user_id']);
    final userName = toStr(json['user_name']);
    final message = toStr(json['message']);
    final dateAdd = parseDt(json['date_add']);
    final userAvatar = toStr(json['user_avatar']);

    return Comment(
      id: id,
      postId: postId,
      groupId: groupId,
      userId: userId,
      userName: userName,
      message: message,
      dateAdd: dateAdd,
      userAvatar: userAvatar,
    );
  }
}

class Post {
  final int id;
  final int postId;
  final int groupId;
  final int userId;
  final String userName;
  final String title;
  final String message;
  final String dateAdd;
  final List<Comment> comments;

  const Post({
    required this.id,
    required this.postId,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.title,
    required this.message,
    required this.dateAdd,
    required this.comments,
  });

  factory Post.fromAPI(Map<String, dynamic> json) {
    final id = toInt(json['id']);
    final postId = toInt(json['post_id']);
    final groupId = toInt(json['group_id']);
    final userId = toInt(json['user_id']);
    final userName = toStr(json['user_name']);
    final title = toStr(json['title']);
    final message = toStr(json['message']);
    final dateAdd = toStr(json['date_add']);
    final listComments = json['comments'];
    final comments = (listComments is List)
        ? listComments.whereType<Map>().map((e) {
            final map = _stringKeyedMap(e);
            return Comment.fromAPI(map);
          }).toList()
        : <Comment>[];
    return Post(
      id: id,
      postId: postId,
      groupId: groupId,
      userId: userId,
      userName: userName,
      title: title,
      message: message,
      dateAdd: dateAdd,
      comments: comments,
    );
  }
}

Map<String, dynamic> _stringKeyedMap(Map raw) {
  final out = <String, dynamic>{};
  raw.forEach((k, v) => out[k.toString()] = v);
  return out;
}

class Community {
  final Group group;
  final List<Post> posts;

  const Community({required this.group, required this.posts});

  factory Community.fromAPI(Map<String, dynamic> json) {
    final group = Group.fromAPI(json['group']);
    final listPosts = json['posts'];
    final posts = (listPosts is List)
        ? listPosts.whereType<Map>().map((e) {
            final map = _stringKeyedMap(e);
            return Post.fromAPI(map);
          }).toList()
        : <Post>[];
    return Community(group: group, posts: posts);
  }
}
