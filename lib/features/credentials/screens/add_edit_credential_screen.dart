import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../models/credential.dart';
import '../models/document.dart';
import '../../../core/services/credential_storage_service.dart';
import 'dart:io';
import 'credential_history_screen.dart';

enum ItemType { credential, document }

class AddEditCredentialScreen extends StatefulWidget {
  final Credential? credential;
  final Document? document;

  const AddEditCredentialScreen({
    Key? key,
    this.credential,
    this.document,
  }) : super(key: key);

  @override
  State<AddEditCredentialScreen> createState() => _AddEditCredentialScreenState();
}

class _AddEditCredentialScreenState extends State<AddEditCredentialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _credentialStorage = CredentialStorageService();
  final _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  ItemType _selectedType = ItemType.credential;

  @override
  void initState() {
    super.initState();
    if (widget.credential != null) {
      _selectedType = ItemType.credential;
      _titleController.text = widget.credential!.title;
      _usernameController.text = widget.credential!.username;
      _passwordController.text = widget.credential!.password;
      _urlController.text = widget.credential!.url ?? '';
      _notesController.text = widget.credential!.notes ?? '';
      if (widget.credential!.iconPath != null) {
        _selectedImage = File(widget.credential!.iconPath!);
      }
    } else if (widget.document != null) {
      _selectedType = ItemType.document;
      _titleController.text = widget.document!.title;
      _documentNumberController.text = widget.document!.documentNumber;
      _notesController.text = widget.document!.notes ?? '';
      if (widget.document!.photoPath != null) {
        _selectedImage = File(widget.document!.photoPath!);
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _shareImage() async {
    if (_selectedImage != null) {
      await Share.shareXFiles([XFile(_selectedImage!.path)]);
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _credentialStorage.init();

      if (_selectedType == ItemType.credential) {
        final credential = Credential(
          id: widget.credential?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          username: _usernameController.text,
          password: _passwordController.text,
          url: _urlController.text.isEmpty ? null : _urlController.text,
          iconPath: _selectedImage?.path,
          isDefaultIcon: _selectedImage == null,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        await _credentialStorage.saveCredential(credential);
      } else {
        final document = Document(
          id: widget.document?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          documentNumber: _documentNumberController.text,
          photoPath: _selectedImage?.path,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        await _credentialStorage.saveDocument(document);
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl() async {
    final url = _urlController.text;
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch URL'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _viewHistory() async {
    if (widget.credential?.id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CredentialHistoryScreen(
          credentialId: widget.credential!.id!,
          credentialTitle: widget.credential!.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.credential == null && widget.document == null 
            ? 'Add ${_selectedType == ItemType.credential ? "Credential" : "Document"}' 
            : 'Edit ${_selectedType == ItemType.credential ? "Credential" : "Document"}'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (widget.credential != null)
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: _viewHistory,
              tooltip: 'View History',
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.credential == null && widget.document == null)
                SegmentedButton<ItemType>(
                  segments: const [
                    ButtonSegment<ItemType>(
                      value: ItemType.credential,
                      label: Text('Credential'),
                      icon: Icon(Icons.lock),
                    ),
                    ButtonSegment<ItemType>(
                      value: ItemType.document,
                      label: Text('Document'),
                      icon: Icon(Icons.description),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<ItemType> selected) {
                    setState(() {
                      _selectedType = selected.first;
                    });
                  },
                ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                            if (_selectedType == ItemType.document)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.share, color: Colors.white),
                                  onPressed: _shareImage,
                                ),
                              ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedType == ItemType.credential
                                  ? Icons.add_photo_alternate
                                  : Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedType == ItemType.credential
                                  ? 'Add Icon'
                                  : 'Add Photo',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedType == ItemType.credential) ...[
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
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
                    prefixIcon: const Icon(Icons.lock),
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
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'URL (optional)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.link),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: _launchUrl,
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      try {
                        Uri.parse(value);
                      } catch (e) {
                        return 'Please enter a valid URL';
                      }
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
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
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
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isLoading ? 'Saving...' : 'Save',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }
} 