import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/create_room_screen.dart';
import 'screens/join_room_screen.dart';
import 'screens/single_player_setup.dart';
import 'screens/waiting_room_screen.dart';
import 'screens/game_screen.dart';
import 'screens/game_result_screen.dart';

class CatchRedThreeApp extends StatelessWidget {
  const CatchRedThreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '抓红3',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/create-room': (_) => const CreateRoomScreen(),
        '/join-room': (_) => const JoinRoomScreen(),
        '/single-player': (_) => const SinglePlayerSetup(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/waiting-room':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => WaitingRoomScreen(
                roomCode: args['roomCode'] as String,
                playerName: args['playerName'] as String,
                maxPlayers: args['maxPlayers'] as int,
                isHost: args['isHost'] as bool,
              ),
            );
          case '/game':
            return MaterialPageRoute(builder: (_) => const GameScreen());
          case '/game-result':
            return MaterialPageRoute(builder: (_) => const GameResultScreen());
          default:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
      },
    );
  }
}
