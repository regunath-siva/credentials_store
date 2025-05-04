import 'package:uuid/uuid.dart';

class Credential {
  final String? id;
  final String title;
  final String username;
  final String password;
  final String? url;
  final String? iconPath;
  final bool isDefaultIcon;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Credential({
    this.id,
    required this.title,
    required this.username,
    required this.password,
    this.url,
    this.iconPath,
    this.isDefaultIcon = true,
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
      'username': username,
      'password': password,
      'url': url,
      'iconPath': iconPath,
      'isDefaultIcon': isDefaultIcon,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Credential.fromJson(Map<String, dynamic> json) {
    return Credential(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      url: json['url'] as String?,
      iconPath: json['iconPath'] as String?,
      isDefaultIcon: json['isDefaultIcon'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Credential copyWith({
    String? title,
    String? username,
    String? password,
    String? url,
    String? iconPath,
    bool? isDefaultIcon,
    String? notes,
    DateTime? updatedAt,
  }) {
    return Credential(
      id: id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      url: url ?? this.url,
      iconPath: iconPath ?? this.iconPath,
      isDefaultIcon: isDefaultIcon ?? this.isDefaultIcon,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
} 