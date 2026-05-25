import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

class ChatPair {
  ChatPair(this.user, this.peerId, this.peerName);
  final User user;
  final String peerId;
  final String peerName;

  String get chatId => Message.chatIdFor(user.id, peerId);
}

final chatPairProvider = Provider.family<ChatPair, String>((ref, peerId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('chatPairProvider: no user');
  return ChatPair(user, peerId, _displayNameFor(peerId));
});

String _displayNameFor(String id) {
  if (id.startsWith('member_dk') || id == 'member_dk') return 'DK';
  if (id.startsWith('member_')) return 'Member ${id.substring(7).toUpperCase()}';
  return id;
}

class ChatViewModel extends FamilyStreamNotifier<List<Message>, String> {
  @override
  Stream<List<Message>> build(String peerId) {
    final pair = ref.watch(chatPairProvider(peerId));
    Future.microtask(() => ref.read(chatServiceProvider).markRead(pair.chatId));
    return ref.watch(chatServiceProvider).watchChat(pair.chatId);
  }

  Future<void> send(String peerId, String text) async {
    final pair = ref.read(chatPairProvider(peerId));
    await ref.read(chatServiceProvider).send(
          chatId: pair.chatId,
          receiverId: pair.peerId,
          text: text,
        );
  }

  void notifyTyping(String peerId) {
    final pair = ref.read(chatPairProvider(peerId));
    ref.read(chatServiceProvider).sendTyping(pair.chatId, pair.peerId);
  }
}

final chatViewModelProvider = StreamNotifierProvider.family<ChatViewModel, List<Message>, String>(
  ChatViewModel.new,
);

final peerTypingProvider = StreamProvider.family<bool, String>((ref, peerId) {
  final pair = ref.watch(chatPairProvider(peerId));
  return ref.watch(chatServiceProvider).watchTyping(pair.chatId);
});

/// Chat list = group last message per chatId for the trainer's contacts.
class ChatThread {
  ChatThread({required this.peerId, required this.peerName, required this.last, required this.unread});
  final String peerId;
  final String peerName;
  final Message last;
  final int unread;
}

/// Chat list driven by the local UserDirectory + ChatService caches.
/// Always returns a row per known member (even before any message has
/// been exchanged) so the trainer's chat list is never empty.
final chatThreadsProvider = StreamProvider<List<ChatThread>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield const [];
    return;
  }
  final dir = ref.watch(userDirectoryProvider);
  final chat = ref.watch(chatServiceProvider);

  Future<List<ChatThread>> build() async {
    final threads = <ChatThread>[];
    for (final m in dir.members) {
      final chatId = Message.chatIdFor(user.id, m.id);
      final cached = chat.cachedMessages(chatId);
      if (cached.isEmpty) {
        threads.add(ChatThread(peerId: m.id, peerName: m.name, last: _placeholder(chatId), unread: 0));
        continue;
      }
      final unread = cached
          .where((x) => x.receiverId == user.id && x.status != MessageStatus.read)
          .length;
      threads.add(ChatThread(peerId: m.id, peerName: m.name, last: cached.last, unread: unread));
    }
    threads.sort((a, b) => b.last.createdAt.compareTo(a.last.createdAt));
    return threads;
  }

  yield await build();
  // Re-emit whenever the user directory changes (new member onboarded).
  await for (final _ in dir.watchAll()) {
    yield await build();
  }
});

Message _placeholder(String chatId) => Message(
      id: 'placeholder_$chatId',
      chatId: chatId,
      senderId: '',
      receiverId: '',
      text: 'Tap to start chatting',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
