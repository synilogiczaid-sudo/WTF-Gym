import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

final pendingRequestsProvider = StreamProvider<List<CallRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(callServiceProvider).watchAll().map((all) {
    return all
        .where((r) => r.trainerId == user.id && r.status == CallRequestStatus.pending)
        .toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  });
});

/// All upcoming approved calls — not just *today*. Keeping a `.day == now.day`
/// filter looked clean on paper but it meant any approval for a future
/// date silently vanished, which made trainers think "Approve" wasn't
/// working. Showing every upcoming approval is the saner default.
final approvedTodayProvider = StreamProvider<List<CallRequest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(callServiceProvider).watchAll().map((all) {
    return all
        .where((r) =>
            r.trainerId == user.id &&
            r.status == CallRequestStatus.approved &&
            !r.isWindowExpired)
        .toList()
      ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  });
});

class RequestActionsViewModel extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> approve(CallRequest req) async {
    final svc = ref.read(callServiceProvider);
    final chat = ref.read(chatServiceProvider);
    final approved = await svc.approve(req);
    final chatId = Message.chatIdFor(req.memberId, req.trainerId);
    await chat.sendSystem(
      chatId: chatId,
      receiverId: req.memberId,
      text: 'Call approved for ${TimeFormat.dateAndTime(approved.scheduledFor)}.',
    );
  }

  Future<void> decline(CallRequest req, String reason) async {
    final svc = ref.read(callServiceProvider);
    final chat = ref.read(chatServiceProvider);
    await svc.decline(req, reason: reason);
    final chatId = Message.chatIdFor(req.memberId, req.trainerId);
    await chat.sendSystem(
      chatId: chatId,
      receiverId: req.memberId,
      text: 'Call request declined. Reason: $reason',
    );
  }
}

final requestActionsProvider =
    AsyncNotifierProvider<RequestActionsViewModel, void>(RequestActionsViewModel.new);
