import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/services/credential_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/credential.dart';
import '../widgets/credential_card.dart';
import '../widgets/screen_header.dart';

class CredentialBinScreen extends StatefulWidget {
  const CredentialBinScreen({Key? key}) : super(key: key);

  @override
  State<CredentialBinScreen> createState() => _CredentialBinScreenState();
}

class _CredentialBinScreenState extends State<CredentialBinScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CredentialStorageService _storageService = CredentialStorageService();
  List<Credential> _deletedCredentials = [];
  List<Credential> _filteredCredentials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    try {
      await _storageService.init();
      final deleted = await _storageService.getDeletedCredentials();
      if (mounted) {
        setState(() {
          _deletedCredentials = deleted;
          _filteredCredentials = _deletedCredentials;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading credentials: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load credentials: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterCredentials(String query) {
    setState(() {
      _filteredCredentials = _deletedCredentials.where((credential) {
        final title = credential.title.toLowerCase();
        final username = credential.username.toLowerCase();
        final notes = credential.notes?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return title.contains(searchQuery) ||
            username.contains(searchQuery) ||
            notes.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _restoreFromBin(Credential credential) async {
    if (credential.id == null) return;

    try {
      await _storageService.restoreFromBin(credential.id!);
      await _loadCredentials();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credential restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore credential: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _permanentlyDelete(Credential credential) async {
    if (credential.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete'),
        content: Text('Are you sure you want to permanently delete ${credential.title}?'),
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
      await _storageService.permanentlyDelete(credential.id!);
      _loadCredentials();
    }
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ScreenHeader(
                      title: 'Bin',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
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
                            hintText: 'Search in bin...',
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
                                      _filterCredentials('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onChanged: _filterCredentials,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(4),
                sliver: _isLoading
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _filteredCredentials.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
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
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index < 0 || index >= _filteredCredentials.length) {
                                  return const SizedBox.shrink();
                                }
                                final credential = _filteredCredentials[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Slidable(
                                    key: ValueKey(credential.id),
                                    endActionPane: ActionPane(
                                      motion: const ScrollMotion(),
                                      extentRatio: 0.5,
                                      children: [
                                        SlidableAction(
                                          onPressed: (_) => _restoreFromBin(credential),
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
                                          onPressed: (_) => _permanentlyDelete(credential),
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
                                    child: CredentialCard(
                                      credential: credential,
                                      showDeleted: true,
                                      onRestore: () => _restoreFromBin(credential),
                                      onDelete: () => _permanentlyDelete(credential),
                                      indicatorColor: Colors.red,
                                    ),
                                  ),
                                );
                              },
                              childCount: _filteredCredentials.length,
                            ),
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
    super.dispose();
  }
}