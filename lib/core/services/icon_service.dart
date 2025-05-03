import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class IconService {
  static final IconService _instance = IconService._internal();
  static const String _iconDirectory = 'credential_icons';

  factory IconService() {
    return _instance;
  }

  IconService._internal();

  Future<String?> saveIcon(File iconFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final iconDir = Directory(path.join(appDir.path, _iconDirectory));
      
      if (!await iconDir.exists()) {
        await iconDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(iconFile.path)}';
      final savedFile = await iconFile.copy(path.join(iconDir.path, fileName));
      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving icon: $e');
      return null;
    }
  }

  Future<void> deleteIcon(String? iconPath) async {
    if (iconPath == null) return;
    
    try {
      final file = File(iconPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting icon: $e');
    }
  }

  Widget getIconWidget(String? iconPath, {double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: iconPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(iconPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _getDefaultIcon(size);
                },
              ),
            )
          : _getDefaultIcon(size),
    );
  }

  Widget _getDefaultIcon(double size) {
    return Icon(
      Icons.lock,
      color: Colors.grey[600],
      size: size * 0.5,
    );
  }

  Future<void> cleanupUnusedIcons(List<String> usedIconPaths) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final iconDir = Directory(path.join(appDir.path, _iconDirectory));
      
      if (!await iconDir.exists()) return;

      final files = await iconDir.list().toList();
      for (var file in files) {
        if (file is File && !usedIconPaths.contains(file.path)) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up icons: $e');
    }
  }
} 