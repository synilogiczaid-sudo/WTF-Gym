import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../viewmodel/chat_viewmodel.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.peerId});
  final String peerId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scroll = ScrollController();
  int _lastCount = 0;
  ScreenSync? _sync;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pair = ref.read(chatPairProvider(widget.peerId));
      _sync = ScreenSync(
        label: 'chat:${pair.chatId}',
        tick: () => ref.read(chatServiceProvider).historyFor(pair.chatId),
      )..start();
    });
  }

  @override
  void dispose() {
    _sync?.stop();
    _scroll.dispose();
    super.dispose();
  }

  void _autoScroll(int count) {
    if (count == _lastCount) return;
    _lastCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pair = ref.watch(chatPairProvider(widget.peerId));
    final msgs = ref.watch(chatViewModelProvider(widget.peerId));
    final typing = ref.watch(peerTypingProvider(widget.peerId)).valueOrNull ?? false;
    final vm = ref.read(chatViewModelProvider(widget.peerId).notifier);

    final peerInitial =
        pair.peerName.isNotEmpty ? pair.peerName.characters.first.toUpperCase() : 'M';

    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: _ChatAppBar(
        peerName: pair.peerName,
        peerInitial: peerInitial,
        subtitle: typing ? 'typing…' : 'Member',
        subtitleColor: typing ? AppColors.success : AppColors.subtle,
        onBack: () => context.go('/home/chats'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: msgs.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const FriendlyError(title: "Couldn't load chat"),
                data: (list) {
                  _autoScroll(list.length);
                  if (list.isEmpty) {
                    return EmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'No messages yet',
                      subtitle: 'Say hi to ${pair.peerName} and get the conversation going.',
                      action: PrimaryButton(
                        label: 'Say hi',
                        icon: Icons.waving_hand_rounded,
                        onPressed: () => vm.send(widget.peerId, 'Hey ${pair.peerName} 👋'),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(chatServiceProvider).historyFor(pair.chatId),
                    child: ListView.builder(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      itemCount: list.length + (typing ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (typing && i == list.length) return const TypingDots();
                        final m = list[i];
                        final isMe = m.senderId == pair.user.id;
                        final senderRole = isMe ? pair.user.role : UserRole.member;
                        return MessageBubble(message: m, senderRole: senderRole, isMe: isMe);
                      },
                    ),
                  );
                },
              ),
            ),
            ChatComposer(
              quickReplies: const [
                'On my way!',
                'Let\'s push another set 💪',
                'Hydrate. Repeat.',
              ],
              onSend: (t) => vm.send(widget.peerId, t),
              onTyping: () => vm.notifyTyping(widget.peerId),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({
    required this.peerName,
    required this.peerInitial,
    required this.subtitle,
    required this.subtitleColor,
    required this.onBack,
  });

  final String peerName;
  final String peerInitial;
  final String subtitle;
  final Color subtitleColor;
  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 64,
      titleSpacing: 0,
      leadingWidth: 44,
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.guruPrimary,
                  Color(0xFF4F8DEB),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              peerInitial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  peerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    subtitle,
                    key: ValueKey(subtitle),
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
