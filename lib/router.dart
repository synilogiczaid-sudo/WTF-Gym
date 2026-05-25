import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import 'features/auth/view/login_screen.dart';
import 'features/call/view/in_call_screen.dart';
import 'features/call/view/pre_join_screen.dart';
import 'features/chat/view/chat_list_screen.dart';
import 'features/chat/view/chat_screen.dart';
import 'features/home/view/home_screen.dart';
import 'features/members/view/members_screen.dart';
import 'features/requests/view/requests_screen.dart';
import 'features/sessions/view/sessions_screen.dart';

final GlobalKey<NavigatorState> trainerRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'trainerRoot');

final trainerRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);
  return GoRouter(
    navigatorKey: trainerRootNavigatorKey,
    initialLocation: auth.currentUser != null ? '/home' : '/login',
    redirect: (context, state) {
      final user = ref.read(authServiceProvider).currentUser;
      final at = state.matchedLocation;
      if (user == null && at != '/login') return '/login';
      if (user != null && at == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
        routes: [
          GoRoute(path: 'members', builder: (_, __) => const MembersScreen()),
          GoRoute(path: 'chats', builder: (_, __) => const ChatListScreen()),
          GoRoute(
            path: 'chats/:peerId',
            builder: (_, state) => ChatScreen(peerId: state.pathParameters['peerId']!),
          ),
          GoRoute(path: 'requests', builder: (_, __) => const RequestsScreen()),
          GoRoute(path: 'sessions', builder: (_, __) => const SessionsScreen()),
          GoRoute(
            path: 'prejoin/:requestId',
            builder: (_, state) =>
                PreJoinScreen(requestId: state.pathParameters['requestId']!),
          ),
          GoRoute(
            path: 'call/:requestId',
            builder: (_, state) =>
                InCallScreen(requestId: state.pathParameters['requestId']!),
          ),
        ],
      ),
    ],
  );
});
