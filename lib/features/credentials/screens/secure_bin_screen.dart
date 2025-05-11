import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/services/credential_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/credential.dart';
import '../models/document.dart';
import '../models/sortable_item.dart';
import '../widgets/credential_card.dart';
import '../widgets/document_card.dart';
import '../widgets/screen_header.dart';
import '../screens/secure_history_screen.dart';

class UnifiedBinScreen extends StatefulWidget {
  const UnifiedBinScreen({Key? key}) : super(key: key);

  @override
  State<UnifiedBinScreen> createState() => _UnifiedBinScreenState();
}

class _UnifiedBinScreenState extends State<UnifiedBinScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CredentialStorageService _storageService = CredentialStorageService();
  List<SortableItem> _deletedItems = [];
  List<SortableItem> _filteredItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedItems();
  }

  Future<void> _loadDeletedItems() async {
    try {
      await _storageService.init();
      final deletedCredentials = await _storageService.getDeletedCredentials();
      final deletedDocuments = await _storageService.getDeletedDocuments();
      
      // Combine and sort by deletion date
      final allItems = <SortableItem>[...deletedCredentials, ...deletedDocuments];
      allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      if (mounted) {
        setState(() {
          _deletedItems = allItems;
          _filteredItems = allItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading deleted items: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load deleted items: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = _deletedItems.where((item) {
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

  Future<void> _restoreFromBin(SortableItem item) async {
    if (item.id == null) return;

    try {
      if (item is Credential) {
        await _storageService.restoreFromBin(item.id!);
      } else if (item is Document) {
        await _storageService.restoreDocumentFromBin(item.id!);
      }
      await _loadDeletedItems();
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

  Future<void> _permanentlyDelete(SortableItem item) async {
    if (item.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete'),
        content: Text('Are you sure you want to permanently delete ${item.title}?'),
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
        if (item is Credential) {
          await _storageService.permanentlyDelete(item.id!);
        } else if (item is Document) {
          await _storageService.permanentlyDeleteDocument(item.id!);
        }
        await _loadDeletedItems();
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
          title: const Text(
            'Bin',
            style: TextStyle(
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
                    hintText: 'Search in bin...',
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
                : _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 64,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bin is empty',
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
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          if (index < 0 || index >= _filteredItems.length) {
                            return const SizedBox.shrink();
                          }
                          final item = _filteredItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Slidable(
                              key: ValueKey(item.id),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                extentRatio: 0.5,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) => _restoreFromBin(item),
                                    backgroundColor: const Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    icon: Icons.restore,
                                    label: 'Restore',
                                    borderRadius: BorderRadius.circular(16),
                                    spacing: 8,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  const SizedBox(width: 8),
                                  SlidableAction(
                                    onPressed: (_) => _permanentlyDelete(item),
                                    backgroundColor: const Color(0xFFF44336),
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_forever,
                                    label: 'Delete',
                                    borderRadius: BorderRadius.circular(16),
                                    spacing: 8,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                ],
                              ),
                              child: item is Credential
                                  ? CredentialCard(
                                      credential: item,
                                      showDeleted: true,
                                      onRestore: () => _restoreFromBin(item),
                                      onDelete: () => _permanentlyDelete(item),
                                      onHistory: () => _viewHistory(item),
                                      indicatorColor: Colors.red,
                                    )
                                  : DocumentCard(
                                      document: item as Document,
                                      showDeleted: true,
                                      onRestore: () => _restoreFromBin(item),
                                      onDelete: () => _permanentlyDelete(item),
                                      onHistory: () => _viewHistory(item),
                                      indicatorColor: Colors.red,
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
    _searchController.dispose();
    super.dispose();
  }
} 