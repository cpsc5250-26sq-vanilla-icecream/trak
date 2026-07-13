int stepsToPoints(int steps) => steps ~/ 100;

/// Returns the start of the step-counting window for today.
///
/// Uses [resetMs] (the cached UTC midnight-Pacific timestamp) when it falls
/// within the current local day. If the cache is absent or stale (i.e. it
/// predates today's local midnight), falls back to today's local midnight so
/// yesterday's steps are never included in today's count.
DateTime resolveStepWindowStart(DateTime now, int? resetMs) {
  final today = DateTime(now.year, now.month, now.day);
  if (resetMs == null) return today;
  final cachedReset = DateTime.fromMillisecondsSinceEpoch(
    resetMs,
    isUtc: true,
  ).toLocal();
  return cachedReset.isAfter(today) ? cachedReset : today;
}
