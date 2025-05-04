import 'package:flutter/material.dart';
import '../../../core/services/credential_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/credential_history.dart';
import '../models/credential.dart';
import '../widgets/screen_header.dart';

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
  bool _isLoading = true;
  List<CredentialHistory> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final storage = CredentialStorageService();
      await storage.init();
      
      if (widget.credentialId.isEmpty) {
        // Load all credentials history
        final credentials = await storage.getCredentials();
        final deletedCredentials = await storage.getDeletedCredentials();
        final allCredentials = [...credentials, ...deletedCredentials];
        
        final allHistory = <CredentialHistory>[];
        for (final cred in allCredentials) {
          if (cred.id != null) {
            final credHistory = await storage.getCredentialHistory(cred.id!);
            allHistory.addAll(credHistory);
          }
        }
        allHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        if (mounted) {
          setState(() {
            _history = allHistory;
            _isLoading = false;
          });
        }
      } else {
        // Load specific credential history
        final history = await storage.getCredentialHistory(widget.credentialId);
        if (mounted) {
          setState(() {
            _history = history;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load history: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFe3f2fd),
                  Color(0xFFffffff),
                ],
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ScreenHeader(
                  title: widget.credentialId.isEmpty 
                      ? 'Credentials History'
                      : 'History: ${widget.credentialTitle}',
                  actions: [
                    IconButton(
                      icon: Icon(_showAllDetails ? Icons.list : Icons.view_agenda),
                      color: AppTheme.primaryColor,
                      onPressed: _toggleShowAllDetails,
                      tooltip: _showAllDetails ? 'Show Summary' : 'Show All Details',
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: _isLoading
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _history.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 64,
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No history found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index < 0 || index >= _history.length) {
                                  return const SizedBox.shrink();
                                }
                                final item = _history[index];
                                final previousItem = index > 0 ? _history[index - 1] : null;
                                return _HistoryCard(
                                  item: item,
                                  previousItem: previousItem,
                                  showAllDetails: _showAllDetails,
                                );
                              },
                              childCount: _history.length,
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
                if (item.credential.notes != null) _buildChangeItem('Notes', item.credential.notes!),
                if (item.credential.url != null) _buildChangeItem('URL', item.credential.url!),
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
    if (item.credential.notes != previousItem!.credential.notes) changes.add('Notes');
    if (item.credential.url != previousItem!.credential.url) changes.add('URL');

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
    if (item.credential.notes != previousItem!.credential.notes) {
      changes.add(_buildChangeComparison('Notes', previousItem!.credential.notes ?? 'Not set', item.credential.notes ?? 'Not set'));
    }
    if (item.credential.url != previousItem!.credential.url) {
      changes.add(_buildChangeComparison('URL', previousItem!.credential.url ?? 'Not set', item.credential.url ?? 'Not set'));
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