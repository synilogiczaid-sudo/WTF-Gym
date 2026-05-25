import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared/shared.dart';

enum SessionsFilter {
  all,
  last7d,
  thisMonth;

  String get label => switch (this) {
        SessionsFilter.all => 'All',
        SessionsFilter.last7d => 'Last 7 days',
        SessionsFilter.thisMonth => 'This Month',
      };

  bool matches(SessionLog l, {DateTime? now}) {
    final n = now ?? DateTime.now();
    switch (this) {
      case SessionsFilter.all:
        return true;
      case SessionsFilter.last7d:
        return l.startedAt.isAfter(n.subtract(const Duration(days: 7)));
      case SessionsFilter.thisMonth:
        return l.startedAt.year == n.year && l.startedAt.month == n.month;
    }
  }
}

final sessionsFilterProvider = StateProvider<SessionsFilter>((_) => SessionsFilter.all);

final trainerSessionsProvider = StreamProvider<List<SessionLog>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  final filter = ref.watch(sessionsFilterProvider);
  return ref.watch(logServiceProvider).watchAll().map((all) {
    return all
        .where((l) => l.trainerId == user.id && filter.matches(l))
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  });
});
