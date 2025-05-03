import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../core/services/credential_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/credential.dart';
import '../widgets/credential_card.dart';
import 'add_edit_credential_screen.dart';
import 'credential_history_screen.dart';

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
  List<Credential> _deletedCredentials = [];
  bool _showDeleted = false;
  late AnimationController _animationController;
  bool _hasShownInitialHints = false;

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
      final deleted = await _storageService.getDeletedCredentials();
      if (mounted) {
        setState(() {
          _credentials = credentials;
          _deletedCredentials = deleted;
          _filteredCredentials = _showDeleted ? _deletedCredentials : _credentials;
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
      _filteredCredentials = (_showDeleted ? _deletedCredentials : _credentials)
          .where((credential) {
        final title = credential.title.toLowerCase();
        final username = credential.username.toLowerCase();
        final url = credential.url?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return title.contains(searchQuery) ||
            username.contains(searchQuery) ||
            url.contains(searchQuery);
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

  Future<void> _restoreFromBin(Credential credential) async {
    if (credential.id == null) return;

    await _storageService.restoreFromBin(credential.id!);
    _loadCredentials();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Search credentials...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onChanged: _filterCredentials,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(_showDeleted ? Icons.restore : Icons.delete),
              onPressed: () {
                setState(() {
                  _showDeleted = !_showDeleted;
                  _filteredCredentials = _showDeleted ? _deletedCredentials : _credentials;
                });
              },
              tooltip: _showDeleted ? 'Show Credentials' : 'Show Bin',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_credentials.isEmpty && !_showDeleted)
          Expanded(
            child: _filteredCredentials.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showDeleted ? 'Bin is empty' : 'No credentials found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCredentials.length,
                    itemBuilder: (context, index) {
                      final credential = _filteredCredentials[index];
                      
                      if (!_hasShownInitialHints) {
                        _hasShownInitialHints = true;
                        Future.delayed(const Duration(milliseconds: 300), () {
                          _animationController.forward();
                        });
                      }

                      return Slidable(
                        key: ValueKey(credential.id),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            if (!_showDeleted) ...[
                              SlidableAction(
                                onPressed: (_) => _viewHistory(credential),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                icon: Icons.history,
                                label: 'History',
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              SlidableAction(
                                onPressed: (_) => _moveToBin(credential),
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Bin',
                              ),
                            ],
                            if (_showDeleted) ...[
                              SlidableAction(
                                onPressed: (_) => _restoreFromBin(credential),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                icon: Icons.restore,
                                label: 'Restore',
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                              ),
                              SlidableAction(
                                onPressed: (_) => _permanentlyDelete(credential),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete_forever,
                                label: 'Delete',
                              ),
                            ],
                          ],
                        ),
                        child: Stack(
                          children: [
                            CredentialCard(
                              credential: credential,
                              onTap: () async {
                                if (!_showDeleted) {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddEditCredentialScreen(
                                        credential: credential,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadCredentials();
                                  }
                                }
                              },
                            ),
                            Positioned(
                              right: 8,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(
                                        8 * (1 - _animationController.value),
                                        0,
                                      ),
                                      child: Opacity(
                                        opacity: _animationController.value,
                                        child: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: AppTheme.primaryColor,
                                          size: 16,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: !_showDeleted
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditCredentialScreen(),
                  ),
                );
                if (result == true) {
                  _loadCredentials();
                }
              },
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
} 