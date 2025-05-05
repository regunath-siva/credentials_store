import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/services/credential_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/document.dart';
import '../widgets/document_card.dart';
import 'add_edit_item_screen.dart';
import 'document_bin_screen.dart';
import 'document_history_screen.dart';

class DocumentsListScreen extends StatefulWidget {
  const DocumentsListScreen({Key? key}) : super(key: key);

  @override
  State<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends State<DocumentsListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final CredentialStorageService _storageService = CredentialStorageService();
  List<Document> _documents = [];
  List<Document> _filteredDocuments = [];
  List<Document> _deletedDocuments = [];
  bool _showDeleted = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  Future<void> _loadDocuments() async {
    try {
      await _storageService.init();
      final documents = await _storageService.getDocuments();
      final deleted = await _storageService.getDeletedDocuments();
      if (mounted) {
        setState(() {
          _documents = documents;
          _deletedDocuments = deleted;
          _filteredDocuments = _showDeleted ? _deletedDocuments : _documents;
        });
      }
    } catch (e) {
      debugPrint('Error loading documents: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load documents: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterDocuments(String query) {
    setState(() {
      _filteredDocuments = (_showDeleted ? _deletedDocuments : _documents)
          .where((document) {
        final title = document.title.toLowerCase();
        final documentNumber = document.documentNumber.toLowerCase();
        final notes = document.notes?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return title.contains(searchQuery) ||
            documentNumber.contains(searchQuery) ||
            notes.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _moveToBin(Document document) async {
    if (document.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Bin'),
        content: Text('Are you sure you want to move ${document.title} to bin?'),
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
        await _storageService.moveDocumentToBin(document.id!);
        await _loadDocuments();
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

  Future<void> _restoreFromBin(Document document) async {
    if (document.id == null) return;

    await _storageService.restoreDocumentFromBin(document.id!);
    _loadDocuments();
  }

  Future<void> _permanentlyDelete(Document document) async {
    if (document.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete'),
        content: Text('Are you sure you want to permanently delete ${document.title}?'),
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
      await _storageService.permanentlyDeleteDocument(document.id!);
      _loadDocuments();
    }
  }

  Future<void> _viewHistory(Document document) async {
    if (document.id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentHistoryScreen(
          documentId: document.id!,
          documentTitle: document.title,
        ),
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
                            'My Documents',
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
                                tooltip: 'View History',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: AppTheme.primaryColor,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const DocumentBinScreen(),
                                    ),
                                  );
                                },
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
                            hintText: 'Search documents...',
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
                                      _filterDocuments('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onChanged: _filterDocuments,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              _filteredDocuments.isEmpty
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
                              _showDeleted ? 'Bin is empty' : 'No documents found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (!_showDeleted) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add a new document',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index < 0 || index >= _filteredDocuments.length) {
                            return const SizedBox.shrink();
                          }
                          final document = _filteredDocuments[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Slidable(
                              key: ValueKey(document.id),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                extentRatio: 0.5,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) => _viewHistory(document),
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
                                    onPressed: (_) => _moveToBin(document),
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
                              child: DocumentCard(
                                document: document,
                                onTap: () async {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddEditCredentialScreen(
                                        document: document,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    await _loadDocuments();
                                    _filterDocuments('');
                                  }
                                },
                                onHistory: () => _viewHistory(document),
                                onBin: () => _moveToBin(document),
                              ),
                            ),
                          );
                        },
                        childCount: _filteredDocuments.length,
                      ),
                    ),
            ],
          ),
        ],
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