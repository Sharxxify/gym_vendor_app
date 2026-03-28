import 'dart:io';
import 'package:flutter/material.dart';

enum KycStatus {
  initial,
  loading,
  success,
  error,
}

class KycProvider extends ChangeNotifier {
  KycStatus _status = KycStatus.initial;
  String? _errorMessage;

  // Document files
  dynamic _businessDocument;
  dynamic _tradeLicense;
  dynamic _ownerIdProof;
  
  // Document URLs (after upload)
  String? _businessDocumentUrl;
  String? _tradeLicenseUrl;
  String? _ownerIdProofUrl;

  // Getters
  KycStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == KycStatus.loading;

  dynamic get businessDocument => _businessDocument;
  dynamic get tradeLicense => _tradeLicense;
  dynamic get ownerIdProof => _ownerIdProof;
  
  String? get businessDocumentUrl => _businessDocumentUrl;
  String? get tradeLicenseUrl => _tradeLicenseUrl;
  String? get ownerIdProofUrl => _ownerIdProofUrl;

  bool get hasRequiredDocuments => 
      (_businessDocument != null || _businessDocumentUrl != null) ||
      (_tradeLicense != null || _tradeLicenseUrl != null) ||
      (_ownerIdProof != null || _ownerIdProofUrl != null);

  /// Function to enable the button - checks if business document and trade license are uploaded
  bool canEnableButton() {
    bool hasBusiness = _businessDocument != null || _businessDocumentUrl != null;
    bool hasTrade = _tradeLicense != null || _tradeLicenseUrl != null;
    return hasBusiness && hasTrade;
  }

  int get uploadedDocumentsCount {
    int count = 0;
    if (_businessDocument != null || _businessDocumentUrl != null) count++;
    if (_tradeLicense != null || _tradeLicenseUrl != null) count++;
    if (_ownerIdProof != null || _ownerIdProofUrl != null) count++;
    return count;
  }

  // Setters
  void setBusinessDocument(dynamic file) {
    _businessDocument = file;
    notifyListeners();
  }

  void setTradeLicense(dynamic file) {
    _tradeLicense = file;
    notifyListeners();
  }

  void setOwnerIdProof(dynamic file) {
    _ownerIdProof = file;
    notifyListeners();
  }

  void setBusinessDocumentUrl(String? url) {
    _businessDocumentUrl = url;
    notifyListeners();
  }

  void setTradeLicenseUrl(String? url) {
    _tradeLicenseUrl = url;
    notifyListeners();
  }

  void setOwnerIdProofUrl(String? url) {
    _ownerIdProofUrl = url;
    notifyListeners();
  }

  // Get all documents as map for upload
  Map<String, File> getDocumentFiles() {
    final docs = <String, File>{};
    if (_businessDocument != null) {
      docs['business_document'] = _businessDocument!;
    }
    if (_tradeLicense != null) {
      docs['trade_license'] = _tradeLicense!;
    }
    if (_ownerIdProof != null) {
      docs['owner_id_proof'] = _ownerIdProof!;
    }
    return docs;
  }

  // Get all document URLs as map
  Map<String, String> getDocumentUrls() {
    final urls = <String, String>{};
    if (_businessDocumentUrl != null) {
      urls['business_document'] = _businessDocumentUrl!;
    }
    if (_tradeLicenseUrl != null) {
      urls['trade_license'] = _tradeLicenseUrl!;
    }
    if (_ownerIdProofUrl != null) {
      urls['owner_id_proof'] = _ownerIdProofUrl!;
    }
    return urls;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _status = KycStatus.initial;
    _errorMessage = null;
    _businessDocument = null;
    _tradeLicense = null;
    _ownerIdProof = null;
    _businessDocumentUrl = null;
    _tradeLicenseUrl = null;
    _ownerIdProofUrl = null;
    notifyListeners();
  }
}
