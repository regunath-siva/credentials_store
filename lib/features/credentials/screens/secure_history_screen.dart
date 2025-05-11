import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/services/credential_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/credential.dart';
import '../models/document.dart';
import '../models/credential_history.dart';
import '../models/document_history.dart';
import '../widgets/credential_card.dart';
import '../widgets/document_card.dart';
import '../widgets/screen_header.dart';

class UnifiedHistoryScreen extends StatefulWidget {
  final String? itemId;
  final String itemTitle;

  const UnifiedHistoryScreen({
    Key? key,
    this.itemId,
    required this.itemTitle,
  }) : super(key: key);

  @override
  State<UnifiedHistoryScreen> createState() => _UnifiedHistoryScreenState();
}

class _UnifiedHistoryScreenState extends State<UnifiedHistoryScreen> with TickerProviderStateMixin {
  final CredentialStorageService _storageService = CredentialStorageService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _historyItems = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  Map<String, bool> _expandedItems = {};
  Map<String, AnimationController> _animationControllers = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _initializeAnimationController(String id) {
    if (!_animationControllers.containsKey(id)) {
      _animationControllers[id] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  void _disposeAnimationController(String id) {
    _animationControllers[id]?.dispose();
    _animationControllers.remove(id);
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = _historyItems.where((item) {
        final searchQuery = query.toLowerCase();
        if (item is CredentialHistory) {
          final title = item.credential.title.toLowerCase();
          final username = item.credential.username.toLowerCase();
          final notes = item.credential.notes?.toLowerCase() ?? '';
          return title.contains(searchQuery) ||
              username.contains(searchQuery) ||
              notes.contains(searchQuery);
        } else if (item is DocumentHistory) {
          final title = item.document.title.toLowerCase();
          final documentNumber = item.document.documentNumber.toLowerCase();
          final notes = item.document.notes?.toLowerCase() ?? '';
          return title.contains(searchQuery) ||
              documentNumber.contains(searchQuery) ||
              notes.contains(searchQuery);
        }
        return false;
      }).toList();
    });
  }

  Future<void> _loadHistory() async {
    try {
      await _storageService.init();
      List<dynamic> historyItems = [];

      if (widget.itemId != null && widget.itemId!.isNotEmpty) {
        final credentialHistory = await _storageService.getCredentialHistory(widget.itemId!);
        final documentHistory = await _storageService.getDocumentHistory(widget.itemId!);
        historyItems = [...credentialHistory, ...documentHistory];
      } else {
        final allCredentialHistory = await _storageService.getAllCredentialHistory();
        final allDocumentHistory = await _storageService.getAllDocumentHistory();
        historyItems = [...allCredentialHistory, ...allDocumentHistory];
      }

      historyItems.sort((a, b) {
        final aTime = a is CredentialHistory ? a.timestamp : (a as DocumentHistory).timestamp;
        final bTime = b is CredentialHistory ? b.timestamp : (b as DocumentHistory).timestamp;
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _historyItems = historyItems;
          _isLoading = false;
        });
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

  Future<void> _restoreItem(dynamic item) async {
    if (item.id == null) return;

    try {
      if (item is CredentialHistory) {
        await _storageService.restoreFromBin(item.credential.id!);
      } else if (item is DocumentHistory) {
        await _storageService.restoreDocumentFromBin(item.document.id!);
      }
      await _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(dynamic item) async {
    if (item.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete'),
        content: Text('Are you sure you want to permanently delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (item is CredentialHistory) {
          await _storageService.permanentlyDelete(item.credential.id!);
        } else if (item is DocumentHistory) {
          await _storageService.permanentlyDeleteDocument(item.document.id!);
        }
        await _loadHistory();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete item: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _viewHistory(dynamic item) async {
    if (item.id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedHistoryScreen(
          itemId: item.id,
          itemTitle: item is CredentialHistory ? item.credential.title : item.document.title,
        ),
      ),
    );
  }

  String _getActionText(String action) {
    switch (action.toLowerCase()) {
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

  Color _getActionColor(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return const Color(0xFF4CAF50);
      case 'updated':
        return const Color(0xFF2196F3);
      case 'deleted':
        return const Color(0xFFFFA726);
      case 'restored':
        return const Color(0xFF9C27B0);
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
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

  Widget _buildDetailsSection(dynamic historyItem) {
    final isCredential = historyItem is CredentialHistory;
    final item = isCredential ? historyItem.credential : historyItem.document;
    final isUpdate = historyItem.action.toLowerCase() == 'updated';
    _initializeAnimationController(historyItem.id);

    return AnimatedBuilder(
      animation: _animationControllers[historyItem.id]!,
      builder: (context, child) {
        return SizeTransition(
          sizeFactor: _animationControllers[historyItem.id]!,
          child: FadeTransition(
            opacity: _animationControllers[historyItem.id]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey[200]!.withOpacity(0),
                          Colors.grey[300]!,
                          Colors.grey[200]!.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                  if (isCredential) ...[
                    if (!isUpdate || historyItem.oldUsername != item.username)
                      _buildDetailTile(
                        'Username',
                        item.username,
                        Icons.person,
                        oldValue: isUpdate ? historyItem.oldUsername : null,
                      ),
                    if (!isUpdate || historyItem.oldPassword != item.password)
                      _buildDetailTile(
                        'Password',
                        item.password,
                        Icons.lock,
                        oldValue: isUpdate ? historyItem.oldPassword : null,
                      ),
                    if (item.url != null && (!isUpdate || historyItem.oldUrl != item.url))
                      _buildDetailTile(
                        'URL',
                        item.url!,
                        Icons.link,
                        oldValue: isUpdate ? historyItem.oldUrl : null,
                      ),
                    if (item.notes != null && (!isUpdate || historyItem.oldNotes != item.notes))
                      _buildDetailTile(
                        'Notes',
                        item.notes!,
                        Icons.note,
                        oldValue: isUpdate ? historyItem.oldNotes : null,
                      ),
                  ] else ...[
                    if (!isUpdate || historyItem.oldDocumentNumber != item.documentNumber)
                      _buildDetailTile(
                        'Document Number',
                        item.documentNumber,
                        Icons.numbers,
                        oldValue: isUpdate ? historyItem.oldDocumentNumber : null,
                      ),
                    if (item.notes != null && (!isUpdate || historyItem.oldNotes != item.notes))
                      _buildDetailTile(
                        'Notes',
                        item.notes!,
                        Icons.note,
                        oldValue: isUpdate ? historyItem.oldNotes : null,
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailTile(String title, String value, IconData icon, {String? oldValue}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(icon, size: 20, color: Colors.grey[600]),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (oldValue != null) ...[
              Text(
                'Old: $oldValue',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: oldValue != null ? const Color(0xFF4CAF50) : Colors.black87,
                fontWeight: oldValue != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            widget.itemId?.isEmpty ?? true ? 'All History' : '${widget.itemTitle} History',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Search in history...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterItems('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onChanged: _filterItems,
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: AppTheme.gradientContainer(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historyItems.isEmpty
                    ? Center(
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
                              'No history available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(4),
                        itemCount: _historyItems.length,
                        itemBuilder: (context, index) {
                          if (index < 0 || index >= _historyItems.length) {
                            return const SizedBox.shrink();
                          }
                          final historyItem = _historyItems[index];
                          final isCredential = historyItem is CredentialHistory;
                          final item = isCredential ? historyItem.credential : historyItem.document;
                          final timestamp = isCredential ? historyItem.timestamp : historyItem.timestamp;
                          final action = isCredential ? historyItem.action : historyItem.action;
                          final isExpanded = _expandedItems[historyItem.id] ?? false;

                          _initializeAnimationController(historyItem.id);
                          if (isExpanded) {
                            _animationControllers[historyItem.id]?.forward();
                          } else {
                            _animationControllers[historyItem.id]?.reverse();
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _expandedItems[historyItem.id] = !isExpanded;
                                        if (isExpanded) {
                                          _animationControllers[historyItem.id]?.reverse();
                                        } else {
                                          _animationControllers[historyItem.id]?.forward();
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _getActionColor(action).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getActionIcon(action),
                                              color: _getActionColor(action),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.title,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  isCredential
                                                      ? 'Username: ${item.username}'
                                                      : 'Document Number: ${item.documentNumber}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: _getActionColor(action).withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      child: Text(
                                                        _getActionText(action),
                                                        style: TextStyle(
                                                          color: _getActionColor(action),
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      timestamp.toString().split('.')[0],
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[500],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            isExpanded ? Icons.expand_less : Icons.expand_more,
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isExpanded) _buildDetailsSection(historyItem),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    super.dispose();
  }
} 