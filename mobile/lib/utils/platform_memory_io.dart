import 'dart:io';

/// Resident set size of the current process, in bytes.
int currentRssBytes() => ProcessInfo.currentRss;
