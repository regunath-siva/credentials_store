import 'package:flutter/material.dart';
import '../../../core/services/credential_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/credential_history.dart';
import '../models/credential.dart';

class CredentialHistoryScreen extends StatefulWidget {
  final String credentialId;
  final String credentialTitle;

  const CredentialHistoryScreen({
    Key? key,
    required this.credentialId,
    required this.credentialTitle,
  }) : super(key: key);

  @override
  State<CredentialHistoryScreen> createState() => _CredentialHistoryScreenState();
}

class _CredentialHistoryScreenState extends State<CredentialHistoryScreen> {
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
        title: Text('History: ${widget.credentialTitle}'),
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
      body: FutureBuilder<List<CredentialHistory>>(
        future: CredentialStorageService().getCredentialHistory(widget.credentialId),
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
  final CredentialHistory item;
  final CredentialHistory? previousItem;
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
                _buildChangeItem('Title', item.credential.title),
                _buildChangeItem('Username', item.credential.username),
                _buildPasswordItem(item.credential.password),
                if (item.credential.url != null) _buildChangeItem('URL', item.credential.url!),
                if (item.credential.notes != null) _buildChangeItem('Notes', item.credential.notes!),
                if (item.credential.iconPath != null) const Text('Icon: Added'),
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
    
    if (item.credential.title != previousItem!.credential.title) changes.add('Title');
    if (item.credential.username != previousItem!.credential.username) changes.add('Username');
    if (item.credential.password != previousItem!.credential.password) changes.add('Password');
    if (item.credential.url != previousItem!.credential.url) changes.add('URL');
    if (item.credential.notes != previousItem!.credential.notes) changes.add('Notes');
    if (item.credential.iconPath != previousItem!.credential.iconPath) changes.add('Icon');

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
      'Created with ${item.credential.title}',
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 14,
      ),
    );
  }

  Widget _buildChangesList() {
    final changes = <Widget>[];

    if (item.credential.title != previousItem!.credential.title) {
      changes.add(_buildChangeComparison('Title', previousItem!.credential.title, item.credential.title));
    }
    if (item.credential.username != previousItem!.credential.username) {
      changes.add(_buildChangeComparison('Username', previousItem!.credential.username, item.credential.username));
    }
    if (item.credential.password != previousItem!.credential.password) {
      changes.add(_buildPasswordComparison(previousItem!.credential.password, item.credential.password));
    }
    if (item.credential.url != previousItem!.credential.url) {
      changes.add(_buildChangeComparison('URL', previousItem!.credential.url ?? 'Not set', item.credential.url ?? 'Not set'));
    }
    if (item.credential.notes != previousItem!.credential.notes) {
      changes.add(_buildChangeComparison('Notes', previousItem!.credential.notes ?? 'Not set', item.credential.notes ?? 'Not set'));
    }
    if (item.credential.iconPath != previousItem!.credential.iconPath) {
      changes.add(_buildChangeComparison('Icon', previousItem!.credential.iconPath ?? 'Not set', item.credential.iconPath ?? 'Not set'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: changes,
    );
  }

  Widget _buildChangeItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordItem(String password) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 80,
            child: Text(
              'Password:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              password,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordComparison(String oldPassword, String newPassword) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Old:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      oldPassword,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      newPassword,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangeComparison(String label, String oldValue, String newValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Old:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      oldValue,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      newValue,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 