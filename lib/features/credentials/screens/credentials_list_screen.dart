import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/services/credential_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/credential.dart';
import '../widgets/credential_card.dart';
import 'add_edit_item_screen.dart';
import 'credential_history_screen.dart';
import 'credential_bin_screen.dart';

class CredentialsListScreen extends StatefulWidget {
  const CredentialsListScreen({Key? key}) : super(key: key);

  @override
  State<CredentialsListScreen> createState() => _CredentialsListScreenState();
}

class _CredentialsListScreenState extends State<CredentialsListScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final CredentialStorageService _storageService = CredentialStorageService();
  List<Credential> _credentials = [];
  List<Credential> _filteredCredentials = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  Future<void> _loadCredentials() async {
    try {
      await _storageService.init();
      final credentials = await _storageService.getCredentials();
      if (mounted) {
        setState(() {
          _credentials = credentials;
          _filteredCredentials = _credentials;
        });
      }
    } catch (e) {
      debugPrint('Error loading credentials: $e');
      if (mounted) {
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
      _filteredCredentials = _credentials.where((credential) {
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

  Future<void> _moveToBin(Credential credential) async {
    if (credential.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Bin'),
        content: Text('Are you sure you want to move ${credential.title} to bin?'),
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
        await _storageService.moveToBin(credential.id!);
        await _loadCredentials();
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

  Future<void> _viewHistory(Credential credential) async {
    if (credential.id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CredentialHistoryScreen(
          credentialId: credential.id!,
          credentialTitle: credential.title,
        ),
      ),
    );
  }

  void _viewBin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CredentialBinScreen(),
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
                            'My Credentials',
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
                                      builder: (context) => const CredentialHistoryScreen(
                                        credentialId: '',
                                        credentialTitle: 'All Credentials',
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
                                      builder: (context) => const CredentialBinScreen(),
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
                            hintText: 'Search credentials...',
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
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              _filteredCredentials.isEmpty
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
                              'No credentials found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add a new credential',
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
                          if (index < 0 || index >= _filteredCredentials.length) {
                            return const SizedBox.shrink();
                          }
                          final credential = _filteredCredentials[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Slidable(
                              key: ValueKey(credential.id),
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                extentRatio: 0.5,
                                children: [
                                  SlidableAction(
                                    onPressed: (_) => _viewHistory(credential),
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
                                    onPressed: (_) => _moveToBin(credential),
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
                              child: CredentialCard(
                                credential: credential,
                                onTap: () async {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddEditItemScreen(
                                        credential: credential,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    await _loadCredentials();
                                    _filterCredentials('');
                                  }
                                },
                                onHistory: () => _viewHistory(credential),
                                onBin: () => _moveToBin(credential),
                              ),
                            ),
                          );
                        },
                        childCount: _filteredCredentials.length,
                      ),
                    ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'credentials_fab',
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditItemScreen(),
            ),
          );
          if (result == true) {
            await _loadCredentials();
            _filterCredentials('');
          }
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