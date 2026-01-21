import '../../domain/news/news_item.dart';
import '../../domain/news/news_repository.dart';

class FakeNewsRepository implements NewsRepository {
  @override
  Future<List<NewsPost>> fetchPosts() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    return const [
      NewsPost(
        id: 'p1',
        author: 'Молитва мира',
        timeLabel: '12 минут назад',
        text:
        'Какое-то описаниеКакое-то описаниеКакое-то описаниеКакое-то описаниеКакое-то описание...',
        hasImage: true,
        likes: 12,
        comments: 3,
      ),
      NewsPost(
        id: 'p2',
        author: 'Молитва мира',
        timeLabel: 'Сегодня 10:00',
        text:
        'Ещё одна новость. Позже заменим на запрос к API и нормальную дату.',
        hasImage: false,
        likes: 5,
        comments: 1,
      ),
      NewsPost(
        id: 'p3',
        author: 'Молитва мира',
        timeLabel: 'Вчера 18:30',
        text:
        'Третья новость (заглушка). Оставляем стиль карточек как в макете.',
        hasImage: true,
        likes: 19,
        comments: 6,
      ),
    ];
  }
}
