import '../funcs/parseFuncs.dart';

class CommunityItem {
  final int id;
  final int type;
  final String invite;
  final int ownerId;
  final String ownerName;
  final String name;
  final String description;
  final DateTime dateAdd;
  final int subscribers;
  final String image;
  final bool subed;
  final bool owner;

  const CommunityItem({
    required this.id,
    required this.type,
    required this.invite,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    required this.description,
    required this.dateAdd,
    required this.subscribers,
    required this.image,
    required this.subed,
    required this.owner
  });

  factory CommunityItem.fromApiJson(Map<String, dynamic> json) {
    final id = toInt(json['id']);
    final typeId = toInt(json['type']);
    final invite = toStr(json['invite']);
    final owner = toInt(json['owner_id']);
    final ownerName = toStr(json['owner_name']);
    final name = toStr(json['name']);
    final desc = toStr(json['description']);
    final date = parseDt(json['date_add']);
    final subs = toInt(json['subscribers']);
    final img = toStr(json['group_image']);
    final isOwner = toBool(json['is_owner']);
    final subed = toBool(json['is_subscribed']);

    return CommunityItem(
      id: id,
      type: typeId,
      invite: invite,
      ownerId: owner,
      ownerName: ownerName,
      name: name,
      description: desc,
      dateAdd: date,
      subscribers: subs,
      image: img,
      owner: isOwner,
      subed: subed
    );
  }
}
