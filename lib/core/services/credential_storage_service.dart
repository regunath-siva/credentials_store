import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../features/credentials/models/credential.dart';
import '../../features/credentials/models/credential_history.dart';
import '../../features/credentials/models/document.dart';
import '../../features/credentials/models/document_history.dart';

class CredentialStorageService {
  static const String _encryptionKeyKey = 'encryption_key';
  static const String _credentialsKey = 'credentials';
  static const String _ivKey = 'credentials_iv';
  static const String _deletedCredentialsKey = 'deleted_credentials';
  static const String _historyKey = 'credential_history';
  static const String _documentsKey = 'documents';
  static const String _deletedDocumentsKey = 'deleted_documents';
  static const String _documentHistoryKey = 'document_history';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final SharedPreferences _prefs;
  late final encrypt.IV _iv;
  bool _isInitialized = false;
  final _uuid = const Uuid();

  Future<void> init() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _initializeEncryption();
    _isInitialized = true;
  }

  Future<void> _initializeEncryption() async {
    String? keyString = await _storage.read(key: _encryptionKeyKey);
    if (keyString == null) {
      final key = encrypt.Key.fromSecureRandom(32);
      keyString = key.base64;
      await _storage.write(key: _encryptionKeyKey, value: keyString);
    }

    // Get or create IV
    String? ivString = _prefs.getString(_ivKey);
    if (ivString == null) {
      _iv = encrypt.IV.fromSecureRandom(16);
      await _prefs.setString(_ivKey, _iv.base64);
    } else {
      _iv = encrypt.IV.fromBase64(ivString);
    }
  }


  Future<List<Credential>> getCredentials() async {
    await init();
    final credentialsJson = await _storage.read(key: _credentialsKey);
    if (credentialsJson == null) return [];
    final List<dynamic> credentialsList = json.decode(credentialsJson);
    return credentialsList.map((json) => Credential.fromJson(json)).toList();
  }

  Future<List<Credential>> getDeletedCredentials() async {
    await init();
    final credentialsJson = await _storage.read(key: _deletedCredentialsKey);
    if (credentialsJson == null) return [];
    final List<dynamic> credentialsList = json.decode(credentialsJson);
    return credentialsList.map((json) => Credential.fromJson(json)).toList();
  }

  Future<List<CredentialHistory>> getCredentialHistory(String credentialId) async {
    await init();
    final historyJson = await _storage.read(key: _historyKey);
    if (historyJson == null) return [];
    
    final List<dynamic> historyList = json.decode(historyJson);
    return historyList
        .map((json) => CredentialHistory.fromJson(json))
        .where((history) => history.credentialId == credentialId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _addToHistory(Credential credential, String action) async {
    await init();
    final historyJson = await _storage.read(key: _historyKey);
    List<dynamic> historyList = [];
    
    if (historyJson != null) {
      historyList = json.decode(historyJson);
    }

    final history = CredentialHistory(
      id: _uuid.v4(),
      credentialId: credential.id!,
      credential: credential,
      timestamp: DateTime.now(),
      action: action,
    );

    historyList.add(history.toJson());

    await _storage.write(
      key: _historyKey,
      value: json.encode(historyList),
    );
  }

  Future<void> saveCredential(Credential credential) async {
    await init();
    final credentials = await getCredentials();
    final index = credentials.indexWhere((c) => c.id == credential.id);
    
    if (index != -1) {
      credentials[index] = credential;
      await _addToHistory(credential, 'updated');
    } else {
      credentials.add(credential);
      await _addToHistory(credential, 'created');
    }

    await _storage.write(
      key: _credentialsKey,
      value: json.encode(credentials.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> deleteCredential(String id) async {
    await init();
    final credentials = await getCredentials();
    credentials.removeWhere((c) => c.id == id);
    await _storage.write(
      key: _credentialsKey,
      value: json.encode(credentials.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> moveToBin(String id) async {
    await init();
    final credentials = await getCredentials();
    final deletedCredentials = await getDeletedCredentials();
    
    final credential = credentials.firstWhere((c) => c.id == id);
    credentials.removeWhere((c) => c.id == id);
    deletedCredentials.add(credential);

    await _addToHistory(credential, 'deleted');

    await _storage.write(
      key: _credentialsKey,
      value: json.encode(credentials.map((c) => c.toJson()).toList()),
    );
    await _storage.write(
      key: _deletedCredentialsKey,
      value: json.encode(deletedCredentials.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> restoreFromBin(String id) async {
    await init();
    final credentials = await getCredentials();
    final deletedCredentials = await getDeletedCredentials();
    
    final credential = deletedCredentials.firstWhere((c) => c.id == id);
    deletedCredentials.removeWhere((c) => c.id == id);
    credentials.add(credential);

    await _addToHistory(credential, 'restored');

    await _storage.write(
      key: _credentialsKey,
      value: json.encode(credentials.map((c) => c.toJson()).toList()),
    );
    await _storage.write(
      key: _deletedCredentialsKey,
      value: json.encode(deletedCredentials.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> permanentlyDelete(String id) async {
    await init();
    final deletedCredentials = await getDeletedCredentials();
    deletedCredentials.removeWhere((c) => c.id == id);

    await _storage.write(
      key: _deletedCredentialsKey,
      value: json.encode(deletedCredentials.map((c) => c.toJson()).toList()),
    );
  }

  Future<List<Document>> getDocuments() async {
    await init();
    final documentsJson = await _storage.read(key: _documentsKey);
    if (documentsJson == null) return [];
    final List<dynamic> documentsList = json.decode(documentsJson);
    return documentsList.map((json) => Document.fromJson(json)).toList();
  }

  Future<List<Document>> getDeletedDocuments() async {
    await init();
    final documentsJson = await _storage.read(key: _deletedDocumentsKey);
    if (documentsJson == null) return [];
    final List<dynamic> documentsList = json.decode(documentsJson);
    return documentsList.map((json) => Document.fromJson(json)).toList();
  }

  Future<List<DocumentHistory>> getDocumentHistory(String documentId) async {
    await init();
    final historyJson = await _storage.read(key: _documentHistoryKey);
    if (historyJson == null) return [];
    
    final List<dynamic> historyList = json.decode(historyJson);
    return historyList
        .map((json) => DocumentHistory.fromJson(json))
        .where((history) => history.documentId == documentId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _addToDocumentHistory(Document document, String action) async {
    await init();
    final historyJson = await _storage.read(key: _documentHistoryKey);
    List<dynamic> historyList = [];
    
    if (historyJson != null) {
      historyList = json.decode(historyJson);
    }

    final history = DocumentHistory(
      id: _uuid.v4(),
      documentId: document.id!,
      document: document,
      timestamp: DateTime.now(),
      action: action,
    );

    historyList.add(history.toJson());

    await _storage.write(
      key: _documentHistoryKey,
      value: json.encode(historyList),
    );
  }

  Future<void> saveDocument(Document document) async {
    await init();
    final documents = await getDocuments();
    final index = documents.indexWhere((d) => d.id == document.id);
    
    if (index != -1) {
      documents[index] = document;
      await _addToDocumentHistory(document, 'updated');
    } else {
      documents.add(document);
      await _addToDocumentHistory(document, 'created');
    }

    await _storage.write(
      key: _documentsKey,
      value: json.encode(documents.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> moveDocumentToBin(String id) async {
    await init();
    final documents = await getDocuments();
    final deletedDocuments = await getDeletedDocuments();
    
    final document = documents.firstWhere((d) => d.id == id);
    documents.removeWhere((d) => d.id == id);
    deletedDocuments.add(document);

    await _addToDocumentHistory(document, 'deleted');

    await _storage.write(
      key: _documentsKey,
      value: json.encode(documents.map((d) => d.toJson()).toList()),
    );
    await _storage.write(
      key: _deletedDocumentsKey,
      value: json.encode(deletedDocuments.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> restoreDocumentFromBin(String id) async {
    await init();
    final documents = await getDocuments();
    final deletedDocuments = await getDeletedDocuments();
    
    final document = deletedDocuments.firstWhere((d) => d.id == id);
    deletedDocuments.removeWhere((d) => d.id == id);
    documents.add(document);

    await _addToDocumentHistory(document, 'restored');

    await _storage.write(
      key: _documentsKey,
      value: json.encode(documents.map((d) => d.toJson()).toList()),
    );
    await _storage.write(
      key: _deletedDocumentsKey,
      value: json.encode(deletedDocuments.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> permanentlyDeleteDocument(String id) async {
    await init();
    final deletedDocuments = await getDeletedDocuments();
    deletedDocuments.removeWhere((d) => d.id == id);
    await _storage.write(
      key: _deletedDocumentsKey,
      value: json.encode(deletedDocuments.map((d) => d.toJson()).toList()),
    );
  }
} 