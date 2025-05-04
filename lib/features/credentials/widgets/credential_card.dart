import 'package:flutter/material.dart';
import '../models/credential.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/icon_service.dart';

class CredentialCard extends StatelessWidget {
  final Credential credential;
  final VoidCallback? onTap;
  final bool showDeleted;
  final VoidCallback? onHistory;
  final VoidCallback? onBin;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;
  final Color indicatorColor;
  final IconService _iconService = IconService();

   CredentialCard({
    Key? key,
    required this.credential,
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
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: _iconService.getIconWidget(credential.iconPath, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              credential.title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              credential.username,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                            if (credential.url != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                credential.url!,
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
                                  title: Text('Bin'),
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
                                  title: Text('Delete'),
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
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
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