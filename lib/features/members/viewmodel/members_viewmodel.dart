import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

/// Live members list backed by the local `UserDirectory`. The directory
/// seeds DK on first launch and merges any users it can fetch from the
/// optional relay — so this list is *never* empty for a demo even if
/// there's zero network.
final membersProvider = StreamProvider<List<User>>((ref) {
  return ref
      .watch(userDirectoryProvider)
      .watchAll()
      .map((all) => all.where((u) => u.role == UserRole.member).toList());
});
