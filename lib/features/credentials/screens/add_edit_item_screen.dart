import 'package:flutter/material.dart';
import '../../../core/services/credential_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/credential.dart';
import '../models/document.dart';

class AddEditItemScreen extends StatefulWidget {
  final Credential? credential;
  final Document? document;

  const AddEditItemScreen({
    Key? key,
    this.credential,
    this.document,
  }) : super(key: key);

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _storageService = CredentialStorageService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.credential != null) {
      _titleController.text = widget.credential!.title;
      _usernameController.text = widget.credential!.username;
      _passwordController.text = widget.credential!.password;
      _notesController.text = widget.credential!.notes ?? '';
    } else if (widget.document != null) {
      _titleController.text = widget.document!.title;
      _documentNumberController.text = widget.document!.documentNumber;
      _notesController.text = widget.document!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _documentNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _storageService.init();
      
      if (widget.credential != null) {
        final credential = Credential(
          id: widget.credential?.id,
          title: _titleController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: widget.credential?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.credential == null) {
          await _storageService.addCredential(credential);
        } else {
          await _storageService.updateCredential(credential);
        }
      } else {
        final document = Document(
          id: widget.document?.id,
          title: _titleController.text.trim(),
          documentNumber: _documentNumberController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          createdAt: widget.document?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.document == null) {
          await _storageService.addDocument(document);
        } else {
          await _storageService.updateDocument(document);
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save item: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCredential = widget.credential != null;
    final title = isCredential ? 'Credential' : 'Document';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(widget.credential == null && widget.document == null ? 'Add $title' : 'Edit $title'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
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
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (isCredential) ...[
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_isPasswordVisible,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a password';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  TextFormField(
                    controller: _documentNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Document Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a document number';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'save_item_fab',
        onPressed: _isLoading ? null : _saveItem,
        backgroundColor: AppTheme.primaryColor,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save),
      ),
    );
  }
} 