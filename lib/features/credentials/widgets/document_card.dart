import 'package:flutter/material.dart';
import 'dart:io';
import '../models/document.dart';
import '../../../core/theme/app_theme.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;
  final bool showDeleted;
  final VoidCallback? onHistory;
  final VoidCallback? onBin;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;
  final Color indicatorColor;

  const DocumentCard({
    Key? key,
    required this.document,
    this.onTap,
    this.showDeleted = false,
    this.onHistory,
    this.onBin,
    this.onRestore,
    this.onDelete,
    this.indicatorColor = AppTheme.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: indicatorColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.description,
                          color: indicatorColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              document.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              document.documentNumber,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                            if (document.notes != null && document.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                document.notes!,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'history' && onHistory != null) onHistory!();
                          if (value == 'bin' && onBin != null) onBin!();
                          if (value == 'restore' && onRestore != null) onRestore!();
                          if (value == 'delete' && onDelete != null) onDelete!();
                        },
                        itemBuilder: (context) {
                          final items = <PopupMenuEntry<String>>[
                            const PopupMenuItem(
                              value: 'history',
                              child: ListTile(
                                leading: Icon(Icons.history),
                                title: Text('History'),
                              ),
                            ),
                          ];

                          if (!showDeleted) {
                            items.add(
                              const PopupMenuItem(
                                value: 'bin',
                                child: ListTile(
                                  leading: Icon(Icons.delete),
                                  title: Text('Move to Bin'),
                                ),
                              ),
                            );
                          } else {
                            items.addAll([
                              const PopupMenuItem(
                                value: 'restore',
                                child: ListTile(
                                  leading: Icon(Icons.restore),
                                  title: Text('Restore'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_forever),
                                  title: Text('Delete Permanently'),
                                ),
                              ),
                            ]);
                          }

                          return items;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (showDeleted)
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 