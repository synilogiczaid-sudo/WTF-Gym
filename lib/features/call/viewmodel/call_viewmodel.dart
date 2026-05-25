import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

final callRequestProvider = StreamProvider.family<CallRequest?, String>((ref, id) {
  return ref.watch(callServiceProvider).watchAll().map(
        (list) => list.where((r) => r.id == id).cast<CallRequest?>().firstOrNull,
      );
});

class CallSessionViewModel extends Notifier<RtcState> {
  DateTime? _startedAt;

  @override
  RtcState build() {
    final svc = ref.watch(rtcServiceProvider);
    final sub = svc.stream.listen((s) => state = s);
    ref.onDispose(sub.cancel);
    return svc.state;
  }

  Future<void> join({
    required String roomId,
    required String userId,
    required String userName,
    required String role,
  }) async {
    final svc = ref.read(rtcServiceProvider);
    final ok = await svc.ensurePermissions();
    if (!ok) {
      throw StateError('Camera & mic permission needed to join the call.');
    }
    _startedAt = DateTime.now();
    await svc.join(roomId: roomId, userId: userId, userName: userName, role: role);
  }

  Future<void> toggleMic() => ref.read(rtcServiceProvider).toggleMic();
  Future<void> toggleCamera() => ref.read(rtcServiceProvider).toggleCamera();
  Future<void> flipCamera() => ref.read(rtcServiceProvider).switchCamera();

  /// Trainer-specific: ends the room for everyone.
  Future<SessionLog?> endForAll({required CallRequest request}) async {
    final svc = ref.read(rtcServiceProvider);
    final startedAt = _startedAt ?? svc.joinedAt ?? DateTime.now();
    final endedAt = DateTime.now();
    await svc.endRoom();
    await svc.leave();
    await ref.read(callServiceProvider).markCompleted(request);
    return ref.read(logServiceProvider).recordSession(
          memberId: request.memberId,
          trainerId: request.trainerId,
          startedAt: startedAt,
          endedAt: endedAt,
        );
  }
}

final callSessionViewModelProvider =
    NotifierProvider<CallSessionViewModel, RtcState>(CallSessionViewModel.new);
