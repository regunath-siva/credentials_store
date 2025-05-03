import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/document.dart';
import '../models/document_history.dart';
import '../../../core/services/credential_storage_service.dart';

class DocumentHistoryScreen extends StatefulWidget {
  final String documentId;
  final String documentTitle;

  const DocumentHistoryScreen({
    Key? key,
    required this.documentId,
    required this.documentTitle,
  }) : super(key: key);

  @override
  State<DocumentHistoryScreen> createState() => _DocumentHistoryScreenState();
}

class _DocumentHistoryScreenState extends State<DocumentHistoryScreen> {
  final CredentialStorageService _storageService = CredentialStorageService();
  List<DocumentHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _storageService.getDocumentHistory(widget.documentId);
    setState(() {
      _history = history;
      _isLoading = false;
    });
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'created':
        return Icons.add_circle;
      case 'updated':
        return Icons.edit;
      case 'deleted':
        return Icons.delete;
      case 'restored':
        return Icons.restore;
      default:
        return Icons.history;
    }
  }

  String _getActionText(String action) {
    switch (action) {
      case 'created':
        return 'Created';
      case 'updated':
        return 'Updated';
      case 'deleted':
        return 'Moved to Bin';
      case 'restored':
        return 'Restored from Bin';
      default:
        return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.documentTitle} History'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No history available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final history = _history[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getActionIcon(history.action),
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getActionText(history.action),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${history.timestamp.hour}:${history.timestamp.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${history.timestamp.day}/${history.timestamp.month}/${history.timestamp.year}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            if (history.document.notes != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Notes: ${history.document.notes}',
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 