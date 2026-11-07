import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:systematic_failure/systematic_failure.dart';

import '../build_info.dart';

class ErrorEntry {
  const ErrorEntry({
    required this.bin,
    required this.errorType,
    this.kind,
    required this.source,
    required this.stackTrace,
    required this.timestamp,
    this.appVersion,
    this.commit,
  });

  final Bin bin;
  final String errorType;
  final String? kind;
  final String source;
  final String stackTrace;
  final DateTime timestamp;
  final String? appVersion;
  final String? commit;

  factory ErrorEntry.fromFailure(
    Failure failure, {
    required String errorType,
    required String source,
    required String stackTrace,
    required DateTime timestamp,
    BuildInfo? buildInfo,
  }) =>
      ErrorEntry(
        bin: failure.bin,
        errorType: errorType,
        kind: failure.kind,
        source: source,
        stackTrace: stackTrace,
        timestamp: timestamp,
        appVersion: buildInfo?.appVersion,
        commit: buildInfo?.commit,
      );

  factory ErrorEntry.fromJson(Map<String, dynamic> json) => ErrorEntry(
        bin: Bin.values.byName(json['bin'] as String),
        errorType: json['errorType'] as String,
        kind: json['kind'] as String?,
        source: json['source'] as String,
        stackTrace: json['stackTrace'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        appVersion: json['appVersion'] as String?,
        commit: json['commit'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'bin': bin.name,
        'errorType': errorType,
        'kind': kind,
        'source': source,
        'stackTrace': stackTrace,
        'timestamp': timestamp.toIso8601String(),
        'appVersion': appVersion,
        'commit': commit,
      };

  Map<String, dynamic> toReportJson() => {
        'schemaVersion': 1,
        'source': source,
        'errorType': errorType,
        // The server still requires a non-null errorCode string.
        'errorCode': bin.name,
        'bin': bin.name,
        'kind': kind,
        'stackTrace': stackTrace,
        'timestamp': timestamp.toIso8601String(),
        'appVersion': appVersion,
        'commit': commit,
      };

  @override
  String toString() =>
      'ErrorEntry(source: $source, errorType: $errorType, bin: ${bin.name})';

  @override
  bool operator ==(Object other) =>
      other is ErrorEntry &&
      bin == other.bin &&
      errorType == other.errorType &&
      kind == other.kind &&
      source == other.source &&
      stackTrace == other.stackTrace &&
      timestamp == other.timestamp &&
      appVersion == other.appVersion &&
      commit == other.commit;

  @override
  int get hashCode => Object.hash(
      bin, errorType, kind, source, stackTrace, timestamp, appVersion, commit);
}

class ErrorBoxEntry {
  const ErrorBoxEntry(
      {required this.id,
      required this.fingerprint,
      required this.errorData,
      required this.occurrenceCount,
      required this.firstOccurred,
      required this.lastOccurred,
      this.wasSent = false,
      this.sentAt});
  final String id;
  final String fingerprint;
  final ErrorEntry errorData;
  final int occurrenceCount;
  final DateTime firstOccurred;
  final DateTime lastOccurred;
  final bool wasSent;
  final DateTime? sentAt;

  ErrorBoxEntry copyWith(
          {int? occurrenceCount,
          DateTime? lastOccurred,
          bool? wasSent,
          DateTime? sentAt}) =>
      ErrorBoxEntry(
          id: id,
          fingerprint: fingerprint,
          errorData: errorData,
          occurrenceCount: occurrenceCount ?? this.occurrenceCount,
          firstOccurred: firstOccurred,
          lastOccurred: lastOccurred ?? this.lastOccurred,
          wasSent: wasSent ?? this.wasSent,
          sentAt: sentAt ?? this.sentAt);
  ErrorBoxEntry incrementCount() => copyWith(
      occurrenceCount: occurrenceCount + 1, lastOccurred: DateTime.now());

  factory ErrorBoxEntry.fromJson(Map<String, dynamic> json) => ErrorBoxEntry(
      id: json['id'] as String,
      fingerprint: json['fingerprint'] as String,
      errorData: ErrorEntry.fromJson(json['errorData'] as Map<String, dynamic>),
      occurrenceCount: json['occurrenceCount'] as int,
      firstOccurred: DateTime.parse(json['firstOccurred'] as String),
      lastOccurred: DateTime.parse(json['lastOccurred'] as String),
      wasSent: json['wasSent'] as bool,
      sentAt: json['sentAt'] == null
          ? null
          : DateTime.parse(json['sentAt'] as String));

  static String generateFingerprint(ErrorEntry error) => sha256
      .convert(utf8.encode(
          '${error.bin.name}:${error.errorType}:${error.kind ?? ''}:${error.source}'))
      .toString();
  Map<String, dynamic> toJson() => {
        'id': id,
        'fingerprint': fingerprint,
        'errorData': errorData.toJson(),
        'occurrenceCount': occurrenceCount,
        'firstOccurred': firstOccurred.toIso8601String(),
        'lastOccurred': lastOccurred.toIso8601String(),
        'wasSent': wasSent,
        'sentAt': sentAt?.toIso8601String()
      };
  @override
  String toString() =>
      'ErrorBoxEntry(id: $id, bin: ${errorData.bin.name}, count: $occurrenceCount, sent: $wasSent)';
  @override
  bool operator ==(Object other) => other is ErrorBoxEntry && id == other.id;
  @override
  int get hashCode => id.hashCode;
}
