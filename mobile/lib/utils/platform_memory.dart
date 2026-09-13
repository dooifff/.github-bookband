/// Fallback implementation for platforms without `dart:io` (e.g. Flutter web).
///
/// Memory reporting is only meaningful where a process exists, so this
/// returns 0 and the performance overlay simply shows no memory usage.
int currentRssBytes() => 0;
