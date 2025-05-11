import 'package:uuid/uuid.dart';
import 'document.dart';

class DocumentHistory {
  final String id;
  final String documentId;
  final Document document;
  final DateTime timestamp;
  final String action;
  final String? oldDocumentNumber;
  final String? oldNotes;

  DocumentHistory({
    required this.id,
    required this.documentId,
    required this.document,
    required this.timestamp,
    required this.action,
    this.oldDocumentNumber,
    this.oldNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'document': document.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      'oldDocumentNumber': oldDocumentNumber,
      'oldNotes': oldNotes,
    };
  }

  factory DocumentHistory.fromJson(Map<String, dynamic> json) {
    return DocumentHistory(
      id: json['id'],
      documentId: json['documentId'],
      document: Document.fromJson(json['document']),
      timestamp: DateTime.parse(json['timestamp']),
      action: json['action'],
      oldDocumentNumber: json['oldDocumentNumber'],
      oldNotes: json['oldNotes'],
    );
  }
} 