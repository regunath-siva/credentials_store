import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const ScreenHeader({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (showBackButton) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: AppTheme.primaryColor,
                      onPressed: onBackPressed ?? () => Navigator.pop(context),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565c0),
                    ),
                  ),
                ],
              ),
              if (actions != null) Row(children: actions!),
            ],
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
} 