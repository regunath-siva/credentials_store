import 'package:flutter/material.dart';
import '../../../core/services/credential_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/document_history.dart';
import '../models/document.dart';

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
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};
  bool _showAllDetails = false;

  void _toggleShowAllDetails() {
    setState(() {
      _showAllDetails = !_showAllDetails;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('History: ${widget.documentTitle}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showAllDetails ? Icons.list : Icons.view_agenda),
            onPressed: _toggleShowAllDetails,
            tooltip: _showAllDetails ? 'Show Summary' : 'Show All Details',
          ),
        ],
      ),
      body: FutureBuilder<List<DocumentHistory>>(
        future: CredentialStorageService().getDocumentHistory(widget.documentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return const Center(
              child: Text('No history available'),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final previousItem = index < history.length - 1 ? history[index + 1] : null;
              
              if (!_itemKeys.containsKey(item.id)) {
                _itemKeys[item.id] = GlobalKey();
              }
              
              return _HistoryCard(
                key: _itemKeys[item.id],
                item: item,
                previousItem: previousItem,
                showAllDetails: _showAllDetails,
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final DocumentHistory item;
  final DocumentHistory? previousItem;
  final bool showAllDetails;

  const _HistoryCard({
    Key? key,
    required this.item,
    this.previousItem,
    required this.showAllDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getActionIcon(item.action),
                      color: _getActionColor(item.action),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getActionText(item.action),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _getActionColor(item.action),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDateTime(item.timestamp),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (item.action == 'updated' && previousItem != null) ...[
              if (showAllDetails) ...[
                const Text(
                  'Changes:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                _buildChangesList(),
              ] else ...[
                _buildSummaryChanges(),
              ],
            ],
            if (item.action == 'created') ...[
              if (showAllDetails) ...[
                _buildChangeItem('Title', item.document.title),
                _buildChangeItem('Document Number', item.document.documentNumber),
                if (item.document.notes != null) _buildChangeItem('Notes', item.document.notes!),
                if (item.document.photoPath != null) const Text('Photo: Added'),
              ] else ...[
                _buildSummaryCreated(),
              ],
            ],
          ],
        ),
      ),
    );
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

  Color _getActionColor(String action) {
    switch (action) {
      case 'created':
        return Colors.green;
      case 'updated':
        return Colors.blue;
      case 'deleted':
        return Colors.red;
      case 'restored':
        return Colors.orange;
      default:
        return Colors.grey;
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  Widget _buildSummaryChanges() {
    final changes = <String>[];
    
    if (item.document.title != previousItem!.document.title) changes.add('Title');
    if (item.document.documentNumber != previousItem!.document.documentNumber) changes.add('Document Number');
    if (item.document.notes != previousItem!.document.notes) changes.add('Notes');
    if (item.document.photoPath != previousItem!.document.photoPath) changes.add('Photo');

    return Text(
      'Updated: ${changes.join(", ")}',
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 14,
      ),
    );
  }

  Widget _buildSummaryCreated() {
    return Text(
      'Created with ${item.document.title}',
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 14,
      ),
    );
  }

  Widget _buildChangesList() {
    final changes = <Widget>[];

    if (item.document.title != previousItem!.document.title) {
      changes.add(_buildChangeComparison('Title', previousItem!.document.title, item.document.title));
    }
    if (item.document.documentNumber != previousItem!.document.documentNumber) {
      changes.add(_buildChangeComparison('Document Number', previousItem!.document.documentNumber, item.document.documentNumber));
    }
    if (item.document.notes != previousItem!.document.notes) {
      changes.add(_buildChangeComparison('Notes', previousItem!.document.notes ?? 'Not set', item.document.notes ?? 'Not set'));
    }
    if (item.document.photoPath != previousItem!.document.photoPath) {
      changes.add(_buildChangeComparison('Photo', previousItem!.document.photoPath ?? 'Not set', item.document.photoPath ?? 'Not set'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: changes,
    );
  }

  Widget _buildChangeItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeComparison(String label, String oldValue, String newValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.arrow_back, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  oldValue,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.arrow_forward, size: 16, color: Colors.green),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  newValue,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 