import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/myDio.dart';
import 'providers.dart';

import 'presentation/auth/activate_email_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/auth/restore_access_screen.dart';

import 'presentation/communities/communities_screen.dart';
import 'presentation/community_details/community_details_screen.dart';
import 'presentation/my_communities/my_communities_screen.dart';
import 'presentation/news/news_screen.dart';
import 'presentation/notifications/notifications_screen.dart';
import 'presentation/post_details/post_details_screen.dart';
import 'presentation/prayer_request/prayer_request_screen.dart';
import 'presentation/profile/profile_screen.dart';
import 'presentation/requests/requests_screen.dart';
import 'presentation/streaming/live_stream_screen.dart';
import 'presentation/streams/streams_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final (dio, jar) = await buildDio();

  runApp(
    ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(dio),
        cookieJarProvider.overrideWithValue(jar),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  static const _brand = Color(0xFF3F4F86);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      title: 'Всем миром',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Montserrat Alternates',
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _brand,
            foregroundColor: Colors.white,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(seedColor: _brand),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: _brand,
          selectionColor: Color(0x333F4F86),
          selectionHandleColor: _brand,
        ),
      ),
      routes: {
        '/activate': (context) {
          final isAccount =
              (ModalRoute.of(context)?.settings.arguments as bool?) ?? true;
          return ActivateEmailScreen(isAccountActivation: isAccount);
        },
        '/': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/news': (_) => const NewsScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/communities': (_) => const CommunitiesScreen(),
        '/streams': (_) => const StreamsScreen(my: false),
        '/pray': (_) => const PrayerRequestScreen(),
        '/requests': (_) => const RequestsScreen(),
        '/my_streams': (_) => const StreamsScreen(my: true),
        '/my_communities': (_) => const MyCommunitiesScreen(),
        '/live_stream': (_) => const LiveStreamScreen(),
        '/restore_access': (_) => const RestoreAccessScreen(),
        CommunityDetailsScreen.routeName: (context) {
          final title = ModalRoute.of(context)!.settings.arguments as String;
          return CommunityDetailsScreen(communityTitle: title);
        },
        PostDetailsScreen.routeName: (context) {
          final postId = ModalRoute.of(context)!.settings.arguments as String;
          return PostDetailsScreen(postId: postId);
        },
      },
    );
  }
}
