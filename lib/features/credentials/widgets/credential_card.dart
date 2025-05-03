import 'package:flutter/material.dart';
import '../models/credential.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/icon_service.dart';

class CredentialCard extends StatelessWidget {
  final Credential credential;
  final VoidCallback? onTap;
  final IconService _iconService = IconService();

  CredentialCard({
    Key? key,
    required this.credential,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _iconService.getIconWidget(credential.iconPath),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credential.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      credential.username,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (credential.url != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        credential.url!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 