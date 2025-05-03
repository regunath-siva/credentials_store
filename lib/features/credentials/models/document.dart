import 'package:uuid/uuid.dart';

class Document {
  final String? id;
  final String title;
  final String documentNumber;
  final String? photoPath;
  final String? notes;

  Document({
    this.id,
    required this.title,
    required this.documentNumber,
    this.photoPath,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'documentNumber': documentNumber,
      'photoPath': photoPath,
      'notes': notes,
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      title: json['title'],
      documentNumber: json['documentNumber'],
      photoPath: json['photoPath'],
      notes: json['notes'],
    );
  }

  Document copyWith({
    String? title,
    String? documentNumber,
    String? photoPath,
    String? notes,
  }) {
    return Document(
      id: id,
      title: title ?? this.title,
      documentNumber: documentNumber ?? this.documentNumber,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
    );
  }
} 