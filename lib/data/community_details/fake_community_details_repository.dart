import '../../domain/community_details/community_details.dart';
import '../../domain/community_details/community_details_repository.dart';
import '../../domain/community_details/community_post.dart';

class FakeCommunityDetailsRepository implements CommunityDetailsRepository {
  @override
  Future<CommunityDetails> fetchCommunityByTitle(String title) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return CommunityDetails(
      title: title,
      description:
      'Это описание сообщества "$title".\n\nПозже заменим на данные из API.',
      membersCount: 1284,
      isSubscribed: true,
    );
  }

  @override
  Future<List<CommunityPost>> fetchCommunityPosts(String title) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    // заглушка: посты “только этого комьюнити”
    return [
      CommunityPost(
        id: 'cp1',
        communityTitle: title,
        author: title,
        timeLabel: '12 минут назад',
        text: 'Пост сообщества "$title". Пока это заглушка.',
        hasImage: true,
        likes: 12,
        comments: 3,
      ),
      CommunityPost(
        id: 'cp2',
        communityTitle: title,
        author: title,
        timeLabel: 'Сегодня 10:00',
        text: 'Ещё один пост этого сообщества. Позже будет API.',
        hasImage: false,
        likes: 5,
        comments: 1,
      ),
      CommunityPost(
        id: 'cp3',
        communityTitle: title,
        author: title,
        timeLabel: 'Вчера 18:30',
        text: 'Третий пост. Отображаем карточкой как в News.',
        hasImage: true,
        likes: 19,
        comments: 6,
      ),
    ];
  }
}
