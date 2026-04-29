import 'community_item.dart';

class CommunityDataItem {

  final List<CommunityItem> items;
  final int totalPages;

  const CommunityDataItem({
    required this.items,
    required this.totalPages
  });
}