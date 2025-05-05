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
import 'credential_history_screen.dart';
import 'document_history_screen.dart';
import 'credential_bin_screen.dart';
import 'document_bin_screen.dart';

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
    try {
      await _storageService.init();
      final credentials = await _storageService.getCredentials();
      final documents = await _storageService.getDocuments();
      
      // Combine and sort by creation date
      final allItems = <SortableItem>[...credentials, ...documents];
      allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      if (mounted) {
        setState(() {
          _items = allItems;
          _filteredItems = allItems;
        });
      }
    } catch (e) {
      debugPrint('Error loading items: $e');
      if (mounted) {
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

    if (item is Credential) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CredentialHistoryScreen(
            credentialId: item.id!,
            credentialTitle: item.title,
          ),
        ),
      );
    } else if (item is Document) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentHistoryScreen(
            documentId: item.id!,
            documentTitle: item.title,
          ),
        ),
      );
    }
  }

  void _viewBin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('View Bin'),
        content: const Text('Select which bin to view'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CredentialBinScreen(),
                ),
              );
            },
            child: const Text('Credentials Bin'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DocumentBinScreen(),
                ),
              );
            },
            child: const Text('Documents Bin'),
          ),
        ],
      ),
    );
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Items',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565c0),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.history),
                                color: AppTheme.primaryColor,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('View History'),
                                      content: const Text('Select which history to view'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const CredentialHistoryScreen(
                                                  credentialId: '',
                                                  credentialTitle: 'All Credentials',
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Credentials History'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const DocumentHistoryScreen(
                                                  documentId: '',
                                                  documentTitle: 'All Documents',
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Documents History'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                tooltip: 'View History',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: AppTheme.primaryColor,
                                onPressed: _viewBin,
                                tooltip: 'View Bin',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.black87),
                          cursorColor: AppTheme.primaryColor,
                          decoration: InputDecoration(
                            hintText: 'Search items...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey[500],
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[500],
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
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              _filteredItems.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No items found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add a new item',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < 0 || index >= _filteredItems.length) {
                            return const SizedBox.shrink();
                          }
                          final item = _filteredItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                        },
                        childCount: _filteredItems.length,
                      ),
                    ),
            ],
          ),
        ],
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

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
} 