import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vsem_mirom/presentation/help/help_screen.dart';
import 'package:vsem_mirom/presentation/prays/prays_screen.dart';
import 'package:vsem_mirom/presentation/request_moderation/request_moderation_screen.dart';

import 'api/myDio.dart';
import 'app/app_reset_scope.dart';
import 'app/deep_links/deep_link_service.dart';
import 'domain/prayer_request/pray_prams.dart';

import 'presentation/auth/activate_email_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/auth/restore_access_screen.dart';

import 'presentation/communities/communities_screen.dart';
import 'presentation/community_details/community_details_screen.dart';
import 'presentation/news/news_screen.dart';
import 'presentation/notifications/notifications_screen.dart';
import 'presentation/prayer_request/prayer_request_screen.dart';
import 'presentation/profile/profile_screen.dart';
import 'presentation/streaming/live_stream_screen.dart';
import 'presentation/streams/streams_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final (dio, jar) = await buildDio();
  await FlutterDownloader.initialize(
    debug: true,
  );

  runApp(
    AppResetScope(
      dio: dio,
      jar: jar,
      child: const App(),
    ),
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  static const _brand = Color(0xFF3F4F86);

  final _navKey = GlobalKey<NavigatorState>();
  late final DeepLinkService _deepLinks;

  @override
  void initState() {
    super.initState();
    _deepLinks = DeepLinkService(_navKey);
    _deepLinks.init();
  }

  @override
  void dispose() {
    _deepLinks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      title: 'Молитва мира',
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
        '/communities': (_) => const CommunitiesScreen(my: false),
        '/streams': (_) => const StreamsScreen(my: false),
        '/pray': (context) {
          final args = (ModalRoute.of(context)!.settings.arguments as Map?);
          if (args == null) {
            return const PrayerRequestScreen();
          }
          return PrayerRequestScreen(params: PrayPrams.fromArgs(args));
        },
        '/prays': (_) => const PraysScreen(),
        '/my_streams': (_) => const StreamsScreen(my: true),
        '/my_communities': (_) => const CommunitiesScreen(my: true),
        '/live_stream': (_) => const LiveStreamScreen(),
        '/restore_access': (_) => const RestoreAccessScreen(),
        '/help': (_) => const HelpChatScreen(),
        '/moderate': (_) => const RequestModerationScreen(),
        CommunityDetailsScreen.routeName: (context) {
          final args =
              (ModalRoute.of(context)!.settings.arguments as Map?) ?? const {};

          final rawId = args['communityID'];
          final communityID = int.tryParse(rawId?.toString() ?? '') ?? 0;

          final invited = (args['invited'] == true) ||
              (args['invited']?.toString().toLowerCase() == 'true');

          final invite = (args['invite'] ?? '').toString();

          debugPrint('[WE ARE IN MAIN] $communityID | $invited | $invite');

          return CommunityDetailsScreen(
            communityID: communityID,
            invited: invited,
            invite: invite,
          );
        },
      },
    );
  }
}