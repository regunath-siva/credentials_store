import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../models/credential.dart';
import '../models/document.dart';
import '../../../core/services/credential_storage_service.dart';
import 'dart:io';
import 'secure_history_screen.dart';

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
        builder: (context) => UnifiedHistoryScreen(
          itemId: widget.credential!.id!,
          itemTitle: widget.credential!.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Check if there are unsaved changes
        if (_titleController.text.isNotEmpty ||
            _usernameController.text.isNotEmpty ||
            _passwordController.text.isNotEmpty ||
            _urlController.text.isNotEmpty ||
            _notesController.text.isNotEmpty ||
            _documentNumberController.text.isNotEmpty ||
            _selectedImage != null) {
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Discard Changes?'),
              content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard'),
                ),
              ],
            ),
          );
          if (shouldPop == true) {
            Navigator.of(context).pop();
          }
          return false;
        }
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.credential == null && widget.document == null
                ? _selectedType == ItemType.credential
                    ? 'Add Credential'
                    : 'Add Document'
                : widget.credential != null
                    ? 'Edit Credential'
                    : 'Edit Document',
          ),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Check if there are unsaved changes
              if (_titleController.text.isNotEmpty ||
                  _usernameController.text.isNotEmpty ||
                  _passwordController.text.isNotEmpty ||
                  _urlController.text.isNotEmpty ||
                  _notesController.text.isNotEmpty ||
                  _documentNumberController.text.isNotEmpty ||
                  _selectedImage != null) {
                final shouldPop = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Discard Changes?'),
                    content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Discard'),
                      ),
                    ],
                  ),
                );
                if (shouldPop == true) {
                  Navigator.of(context).pop();
                }
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
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
        body: SafeArea(
          child: AppTheme.gradientContainer(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(4),
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          AnimatedAlign(
                            alignment: _selectedType == ItemType.credential
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                            child: FractionallySizedBox(
                              widthFactor: 0.5,
                              heightFactor: 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(28),
                                  onTap: () {
                                    setState(() {
                                      _selectedType = ItemType.credential;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.lock,
                                          color: _selectedType == ItemType.credential
                                              ? Colors.white
                                              : AppTheme.primaryColor,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Credential',
                                          style: TextStyle(
                                            color: _selectedType == ItemType.credential
                                                ? Colors.white
                                                : AppTheme.primaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(28),
                                  onTap: () {
                                    setState(() {
                                      _selectedType = ItemType.document;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.description,
                                          color: _selectedType == ItemType.document
                                              ? Colors.white
                                              : AppTheme.primaryColor,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Document',
                                          style: TextStyle(
                                            color: _selectedType == ItemType.document
                                                ? Colors.white
                                                : AppTheme.primaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_selectedType == ItemType.document)
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _selectedImage != null
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
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
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add Photo',
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
                      decoration: InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryColor),
                        ),
                        prefixIcon: const Icon(Icons.title),
                        filled: true,
                        fillColor: Colors.grey[50],
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
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor),
                          ),
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: Colors.grey[50],
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor),
                          ),
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
                          filled: true,
                          fillColor: Colors.grey[50],
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor),
                          ),
                          prefixIcon: const Icon(Icons.link),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: _launchUrl,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
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
                        decoration: InputDecoration(
                          labelText: 'Document Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.primaryColor),
                          ),
                          prefixIcon: const Icon(Icons.numbers),
                          filled: true,
                          fillColor: Colors.grey[50],
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
                      decoration: InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryColor),
                        ),
                        prefixIcon: const Icon(Icons.note),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _isLoading ? 'Saving...' : 'Save',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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