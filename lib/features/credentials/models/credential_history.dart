import 'credential.dart';

class CredentialHistory {
  final String id;
  final String credentialId;
  final Credential credential;
  final DateTime timestamp;
  final String action; // 'created', 'updated', 'deleted', 'restored'
  final String? oldUsername;
  final String? oldPassword;
  final String? oldUrl;
  final String? oldNotes;

  CredentialHistory({
    required this.id,
    required this.credentialId,
    required this.credential,
    required this.timestamp,
    required this.action,
    this.oldUsername,
    this.oldPassword,
    this.oldUrl,
    this.oldNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'credentialId': credentialId,
      'credential': credential.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'oldUsername': oldUsername,
      'oldPassword': oldPassword,
      'oldUrl': oldUrl,
      'oldNotes': oldNotes,
    };
  }

  factory CredentialHistory.fromJson(Map<String, dynamic> json) {
    return CredentialHistory(
      id: json['id'],
      credentialId: json['credentialId'],
      credential: Credential.fromJson(json['credential']),
      timestamp: DateTime.parse(json['timestamp']),
      action: json['action'],
      oldUsername: json['oldUsername'],
      oldPassword: json['oldPassword'],
      oldUrl: json['oldUrl'],
      oldNotes: json['oldNotes'],
    );
  }
} 