import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/services/credential_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/credential.dart';
import '../models/document.dart';
import '../models/sortable_item.dart';
import '../widgets/credential_card.dart';
import '../widgets/document_card.dart';
import 'add_edit_item_screen.dart';
import 'secure_bin_screen.dart';
import 'secure_history_screen.dart';

class UnifiedListScreen extends StatefulWidget {
  const UnifiedListScreen({Key? key}) : super(key: key);

  @override
  State<UnifiedListScreen> createState() => _UnifiedListScreenState();
}

class _UnifiedListScreenState extends State<UnifiedListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final CredentialStorageService _storageService = CredentialStorageService();
  List<SortableItem> _items = [];
  List<SortableItem> _filteredItems = [];
  late AnimationController _animationController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _storageService.init();
      final credentials = await _storageService.getCredentials();
      final documents = await _storageService.getDocuments();
      final allItems = <SortableItem>[...credentials, ...documents];
      allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) {
        setState(() {
          _items = allItems;
          _filteredItems = allItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading items: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load items: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = _items.where((item) {
        final searchQuery = query.toLowerCase();
        if (item is Credential) {
          final title = item.title.toLowerCase();
          final username = item.username.toLowerCase();
          final notes = item.notes?.toLowerCase() ?? '';
          return title.contains(searchQuery) ||
              username.contains(searchQuery) ||
              notes.contains(searchQuery);
        } else if (item is Document) {
          final title = item.title.toLowerCase();
          final documentNumber = item.documentNumber.toLowerCase();
          final notes = item.notes?.toLowerCase() ?? '';
          return title.contains(searchQuery) ||
              documentNumber.contains(searchQuery) ||
              notes.contains(searchQuery);
        }
        return false;
      }).toList();
    });
  }

  Future<void> _moveToBin(SortableItem item) async {
    if (item.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Bin'),
        content: Text('Are you sure you want to move ${item.title} to bin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Move to Bin'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storageService.init();
        if (item is Credential) {
          await _storageService.moveToBin(item.id!);
        } else if (item is Document) {
          await _storageService.moveDocumentToBin(item.id!);
        }
        await _loadItems();
      } catch (e) {
        debugPrint('Error moving to bin: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to move to bin: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _viewHistory(SortableItem item) async {
    if (item.id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedHistoryScreen(
          itemId: item.id,
          itemTitle: item.title,
        ),
      ),
    );
  }

  void _viewBin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UnifiedBinScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Secure Vault',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UnifiedHistoryScreen(
                    itemId: '',
                    itemTitle: 'All Items',
                  ),
                ),
              );
            },
            tooltip: 'View History',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _viewBin,
            tooltip: 'View Bin',
          ),
        ],
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
                  hintText: 'Search items...',
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.18),
                                blurRadius: 32,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            size: 54,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 28),
                        const SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 4.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Loading your vault...',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please wait while we securely load your items',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.18),
                                    blurRadius: 32,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock_outline,
                                size: 54,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'No items found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first item to get started',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return _buildItemCard(item);
                        },
                      ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditCredentialScreen(),
            ),
          ).then((result) {
            if (result == true) {
              _loadItems();
              _filterItems('');
            }
          });
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildItemCard(SortableItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Slidable(
        key: ValueKey(item.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.5,
          children: [
            SlidableAction(
              onPressed: (_) => _viewHistory(item),
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              icon: Icons.history,
              label: 'History',
              borderRadius: BorderRadius.circular(16),
              spacing: 8,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            const SizedBox(width: 8),
            SlidableAction(
              onPressed: (_) => _moveToBin(item),
              backgroundColor: const Color(0xFFFFA726),
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Bin',
              borderRadius: BorderRadius.circular(16),
              spacing: 8,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ],
        ),
        child: item is Credential
            ? CredentialCard(
                credential: item,
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditCredentialScreen(
                        credential: item,
                      ),
                    ),
                  );
                  if (result == true) {
                    await _loadItems();
                    _filterItems('');
                  }
                },
                onHistory: () => _viewHistory(item),
                onBin: () => _moveToBin(item),
              )
            : DocumentCard(
                document: item as Document,
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditCredentialScreen(
                        document: item,
                      ),
                    ),
                  );
                  if (result == true) {
                    await _loadItems();
                    _filterItems('');
                  }
                },
                onHistory: () => _viewHistory(item),
                onBin: () => _moveToBin(item),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}