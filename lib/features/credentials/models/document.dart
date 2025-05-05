import 'package:uuid/uuid.dart';
import 'sortable_item.dart';

class Document implements SortableItem {
  final String? id;
  final String title;
  final String documentNumber;
  final String? photoPath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Document({
    this.id,
    required this.title,
    required this.documentNumber,
    this.photoPath,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'documentNumber': documentNumber,
      'photoPath': photoPath,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      documentNumber: json['documentNumber'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Document copyWith({
    String? title,
    String? documentNumber,
    String? photoPath,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id,
      title: title ?? this.title,
      documentNumber: documentNumber ?? this.documentNumber,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
} 