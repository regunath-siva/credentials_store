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

  Credential({
    this.id,
    required this.title,
    required this.username,
    required this.password,
    this.url,
    this.iconPath,
    this.isDefaultIcon = true,
    this.notes,
  });

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
    };
  }

  factory Credential.fromJson(Map<String, dynamic> json) {
    return Credential(
      id: json['id'],
      title: json['title'],
      username: json['username'],
      password: json['password'],
      url: json['url'],
      iconPath: json['iconPath'],
      isDefaultIcon: json['isDefaultIcon'] ?? true,
      notes: json['notes'],
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
    );
  }
} 