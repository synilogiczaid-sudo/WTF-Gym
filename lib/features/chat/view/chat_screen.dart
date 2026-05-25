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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pair = ref.watch(chatPairProvider(widget.peerId));
    final msgs = ref.watch(chatViewModelProvider(widget.peerId));
    final typing = ref.watch(peerTypingProvider(widget.peerId)).valueOrNull ?? false;
    final vm = ref.read(chatViewModelProvider(widget.peerId).notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home/chats'),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.guruPrimary.withValues(alpha: 0.15),
              child: Text(
                pair.peerName.characters.first.toUpperCase(),
                style: const TextStyle(color: AppColors.guruPrimary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pair.peerName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
                const Text('Member', style: TextStyle(fontSize: 11, color: AppColors.subtle)),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
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
                      title: 'No messages yet. Start the conversation.',
                      subtitle: 'Say hi to ${pair.peerName}.',
                      action: PrimaryButton(
                        label: 'Say hi',
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
              onSend: (t) => vm.send(widget.peerId, t),
              onTyping: () => vm.notifyTyping(widget.peerId),
            ),
          ],
        ),
      ),
    );
  }
}
