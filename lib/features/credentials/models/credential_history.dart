import 'credential.dart';

class CredentialHistory {
  final String id;
  final String credentialId;
  final Credential credential;
  final DateTime timestamp;
  final String action; // 'created', 'updated', 'deleted', 'restored'

  CredentialHistory({
    required this.id,
    required this.credentialId,
    required this.credential,
    required this.timestamp,
    required this.action,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'credentialId': credentialId,
      'credential': credential.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'action': action,
    };
  }

  factory CredentialHistory.fromJson(Map<String, dynamic> json) {
    return CredentialHistory(
      id: json['id'],
      credentialId: json['credentialId'],
      credential: Credential.fromJson(json['credential']),
      timestamp: DateTime.parse(json['timestamp']),
      action: json['action'],
    );
  }
} 