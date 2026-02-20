ihttps://www.youtube.com/watch?v=FtrPcShJmREmport 'dart:async';
import 'dart:ui';
import 'package:audiobinge/app.dart';
import 'package:audiobinge/pages/downloadsPage.dart';
import 'package:audiobinge/pages/searchPage.dart';
import 'package:audiobinge/services/donwloadService.dart';
import 'package:audiobinge/services/player.dart';
import 'package:audiobinge/theme/isDark.dart';
import 'package:audiobinge/theme/theme.dart';
import 'package:audiobinge/utils/custom_appbar.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/youtubePage.dart';
import 'pages/playlist/playlists_page.dart';
import 'components/bottomPlayer.dart';
import 'services/youtubeAudioStream.dart';
import 'provider/connectivityProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeState = ThemeModeState();
  await themeState.getTheme();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
    // androidNotificationIcon: '@mipmap/launcher_icon');
  );
  void _reportError(Object error, StackTrace? stack) {
    // Example: print or send to Sentry, Firebase, or your own API
    debugPrint('Caught error: $error');
    debugPrint('Stack trace: $stack');
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    // You can also send the error to your server or a crash logging service
    _reportError(details.exception, details.stack);
  };

  runZonedGuarded(() {
    runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeState),
        ChangeNotifierProxyProvider<ThemeModeState, ThemeService>(
          create: (_) => ThemeService(themeState), // dummy init
          update: (_, themeMode, previous) => ThemeService(themeMode),
        ),
        ChangeNotifierProvider(create: (_) => LikeNotifier()),
        ChangeNotifierProvider(create: (_) => Playing()),
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
        Provider<DownloadService>(create: (context) => DownloadService()),
      ],
      child: MyApp(),
    ));
  }, (Object error, StackTrace stack) {
    _reportError(error, stack);
  });
}

class YouTubeTwitchTabs extends StatefulWidget {
  const YouTubeTwitchTabs({super.key});

  @override
  _YouTubeTwitchTabsState createState() => _YouTubeTwitchTabsState();
}

class _YouTubeTwitchTabsState extends State<YouTubeTwitchTabs> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    YoutubeScreen(),
    SearchScreen(),
    PlaylistsScreen(),
    DownloadScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final playing = context.watch<Playing>();
    return Scaffold(
      extendBody: true,
      appBar: CustomAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade800, Colors.black],
          ),
        ),
        child: Stack(
          children: [
            // Main content with fade transition
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _pages[_selectedIndex],
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),

            // BottomPlayer positioned above the bottom navigation
            if (playing.video.videoId != null && playing.isPlayerVisible)
              Positioned(
                left: 0,
                right: 0,
                bottom: kBottomNavigationBarHeight +
                    32, // Position above the bottom nav
                child: Dismissible(
                  key: Key("bottomPlayer"),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (_) {
                    playing.hidePlayer();
                    playing.stop();
                  },
                  child: BottomPlayer(),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Theme.of(context)
                .scaffoldBackgroundColor
                .withValues(alpha: 0.5),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              //  AppColors.primaryColor,
              // unselectedItemColor: Colors.grey,
              selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.video_library),
                  label: 'YouTube',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.my_library_music),
                  label: 'Playlists',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.download_for_offline_rounded),
                  label: 'Downloads',
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
