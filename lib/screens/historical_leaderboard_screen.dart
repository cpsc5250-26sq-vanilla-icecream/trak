import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../database/app_database.dart';
import '../providers/app_providers.dart';
import '../widgets/leaderboard_widget.dart';

class HistoricalLeaderboardScreen extends ConsumerStatefulWidget {
  const HistoricalLeaderboardScreen({super.key});

  @override
  ConsumerState<HistoricalLeaderboardScreen> createState() =>
      _HistoricalLeaderboardScreenState();
}

class _HistoricalLeaderboardScreenState
    extends ConsumerState<HistoricalLeaderboardScreen> {
  late DateTime _selected;
  late DateTime _focused;
  late DateTime _lastDay;

  static DateTime _utcYesterday() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
  }

  @override
  void initState() {
    super.initState();
    _lastDay = _utcYesterday();
    _selected = _lastDay;
    _focused = _lastDay;
    _loadYesterday();
  }

  Future<void> _loadYesterday() async {
    try {
      final resetMs = await AppDatabase.instance.getResetTimeUtc(
        AppDatabase.defaultLeaderboardId,
      );
      if (resetMs == null || !mounted) return;
      final resetUtc = DateTime.fromMillisecondsSinceEpoch(
        resetMs,
        isUtc: true,
      );
      final yesterday = DateTime.utc(
        resetUtc.year,
        resetUtc.month,
        resetUtc.day,
      ).subtract(const Duration(days: 1));
      setState(() {
        _lastDay = yesterday;
        _selected = yesterday;
        _focused = yesterday;
      });
    } catch (e) {
      debugPrint('Failed to load reset time from DB: $e');
    }
  }

  String get _isoDate =>
      '${_selected.year}-'
      '${_selected.month.toString().padLeft(2, '0')}-'
      '${_selected.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserProvider).asData?.value.userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Past Leaderboards')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: _lastDay,
            focusedDay: _focused,
            selectedDayPredicate: (day) => isSameDay(day, _selected),
            onDaySelected: (selected, focused) => setState(() {
              _selected = selected;
              _focused = focused;
            }),
            onPageChanged: (focused) => setState(() => _focused = focused),
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _HistoricalContent(
              date: _isoDate,
              currentUserId: currentUserId,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoricalContent extends ConsumerWidget {
  final String date;
  final String? currentUserId;

  const _HistoricalContent({required this.date, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(historicalLeaderboardProvider(date));

    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text('No leaderboard for this day.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (_, i) => LeaderboardRow(
            entry: entries[i],
            isCurrentUser: entries[i].userId == currentUserId,
          ),
        );
      },
    );
  }
}
