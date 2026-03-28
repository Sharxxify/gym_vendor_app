
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/gym_service.dart';
import '../services/customer_service.dart';

enum BusinessStatus {
  initial,
  loading,
  success,
  error,
}

class BusinessProvider extends ChangeNotifier {
  final GymService _gymService = GymService();
  final CustomerService _customerService = CustomerService();

  BusinessStatus _status = BusinessStatus.initial;
  String? _errorMessage;
  Business? _business;
  bool _isUploading = false;
  String? _uploadingPurpose; // What's currently being uploaded

  // Form fields - ONLY URLs, no File storage
  String _businessName = '';
  String _email = '';
  String _aboutUs = '';
  List<String> _displayImageUrls = []; // Already uploaded URLs
  String? _displayVideoUrl; // Max 30-second display video
  String? _profilePictureUrl; // Already uploaded URL
  Address? _address;
  double? _latitude;
  double? _longitude;
  String? _formattedAddress;
  BusinessHours _businessHours = BusinessHours.defaultHours();
  List<Service> _services = [];
  List<Facility> _facilities = [];
  List<Equipment> _equipments = [];
  MembershipFee? _membershipFee;

  // KYC Documents - ONLY URLs
  Map<String, String> _kycDocumentUrls = {}; // type -> view_url

  // Gym profile data after creation
  Map<String, dynamic>? _gymProfileData;
  List<Transaction>? _initialTransactions;

  // Getters
  BusinessStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Business? get business => _business;
  bool get isLoading => _status == BusinessStatus.loading;
  bool get isUploading => _isUploading;
  String? get uploadingPurpose => _uploadingPurpose;

  String get businessName => _businessName;
  String get email => _email;
  String get aboutUs => _aboutUs;
  List<String> get displayImageUrls => _displayImageUrls;
  String? get displayVideoUrl => _displayVideoUrl;
  String? get profilePictureUrl => _profilePictureUrl;
  Address? get address => _address;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get formattedAddress => _formattedAddress;
  BusinessHours get businessHours => _businessHours;
  List<Service> get services => _services;
  List<Facility> get facilities => _facilities;
  List<Equipment> get equipments => _equipments;
  MembershipFee? get membershipFee => _membershipFee;
  Map<String, String> get kycDocumentUrls => _kycDocumentUrls;
  Map<String, dynamic>? get gymProfileData => _gymProfileData;
  List<Transaction>? get initialTransactions => _initialTransactions;

  bool get canContinueBusinessDetails =>
      _businessName.isNotEmpty && _latitude != null && _longitude != null;

  bool get hasKycDocuments => _kycDocumentUrls.isNotEmpty;

  bool get hasDisplayImages => _displayImageUrls.isNotEmpty;

  bool get hasBusinessHours {
    return _businessHours.monday.isOpen ||
        _businessHours.tuesday.isOpen ||
        _businessHours.wednesday.isOpen ||
        _businessHours.thursday.isOpen ||
        _businessHours.friday.isOpen ||
        _businessHours.saturday.isOpen ||
        _businessHours.sunday.isOpen;
  }

  // ============ SETTERS ============

  void setBusinessName(String name) {
    _businessName = name;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setAboutUs(String about) {
    _aboutUs = about;
    notifyListeners();
  }

  void setLocation(double lat, double lng, String address) {
    _latitude = lat;
    _longitude = lng;
    _formattedAddress = address;
    notifyListeners();
  }

  void setAddress(Address address) {
    _address = address;
    notifyListeners();
  }

  void updateBusinessHours(BusinessHours hours) {
    _businessHours = hours;
    notifyListeners();
  }

  void updateDayHours(int dayIndex, DayHours dayHours) {
    switch (dayIndex) {
      case 0:
        _businessHours = _businessHours.copyWith(monday: dayHours);
        break;
      case 1:
        _businessHours = _businessHours.copyWith(tuesday: dayHours);
        break;
      case 2:
        _businessHours = _businessHours.copyWith(wednesday: dayHours);
        break;
      case 3:
        _businessHours = _businessHours.copyWith(thursday: dayHours);
        break;
      case 4:
        _businessHours = _businessHours.copyWith(friday: dayHours);
        break;
      case 5:
        _businessHours = _businessHours.copyWith(saturday: dayHours);
        break;
      case 6:
        _businessHours = _businessHours.copyWith(sunday: dayHours);
        break;
    }
    notifyListeners();
  }

  void addService(Service service) {
    _services.add(service);
    notifyListeners();
  }

  void removeService(int index) {
    if (index >= 0 && index < _services.length) {
      _services.removeAt(index);
      notifyListeners();
    }
  }

  void updateService(int index, Service service) {
    if (index >= 0 && index < _services.length) {
      _services[index] = service;
      notifyListeners();
    }
  }

  void setFacilities(List<Facility> facilities) {
    _facilities = facilities;
    notifyListeners();
  }

  void toggleFacility(String facilityName, {double? price, String? unit}) {
    final index = _facilities.indexWhere((f) => f.name == facilityName);
    if (index != -1) {
      _facilities.removeAt(index);
    } else {
      _facilities.add(Facility(
          name: facilityName,
          isIncluded: true,
          price: price ?? 0.0,
          unit: unit));
    }
    notifyListeners();
  }

  void addEquipment(Equipment equipment) {
    _equipments.add(equipment);
    notifyListeners();
  }

  void removeEquipment(int index) {
    if (index >= 0 && index < _equipments.length) {
      _equipments.removeAt(index);
      notifyListeners();
    }
  }

  void setMembershipFee(MembershipFee fee) {
    _membershipFee = fee;
    notifyListeners();
  }

  void removeDisplayImage(int index) {
    if (index >= 0 && index < _displayImageUrls.length) {
      _displayImageUrls.removeAt(index);
      notifyListeners();
    }
  }

  void removeDisplayVideo() {
    _displayVideoUrl = null;
    notifyListeners();
  }

  void removeKycDocument(String type) {
    _kycDocumentUrls.remove(type);
    notifyListeners();
  }

  // ============ IMMEDIATE UPLOAD METHODS ============

  /// Upload display image immediately and store the URL
  Future<bool> uploadDisplayImage(dynamic file) async {
    _isUploading = true;
    _uploadingPurpose = 'display_image';
    notifyListeners();

    try {
      debugPrint('📤 Uploading display image immediately...');
      final viewUrl = await _gymService.uploadFile(file, 'display_image');

      if (viewUrl != null) {
        _displayImageUrls.add(viewUrl);
        debugPrint('✅ Display image uploaded: $viewUrl');
        _isUploading = false;
        _uploadingPurpose = null;
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ Failed to upload display image');
        _isUploading = false;
        _uploadingPurpose = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error uploading display image: $e');
      _isUploading = false;
      _uploadingPurpose = null;
      notifyListeners();
      return false;
    }
  }

  /// Upload display video immediately and store the URL
  Future<bool> uploadDisplayVideo(dynamic file) async {
    _isUploading = true;
    _uploadingPurpose = 'display_video';
    notifyListeners();

    try {
      debugPrint('📤 Uploading display video immediately...');
      final viewUrl = await _gymService.uploadFile(file, 'display_video');

      if (viewUrl != null) {
        _displayVideoUrl = viewUrl;
        debugPrint('✅ Display video uploaded: $viewUrl');
        _isUploading = false;
        _uploadingPurpose = null;
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ Failed to upload display video');
        _isUploading = false;
        _uploadingPurpose = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error uploading display video: $e');
      _isUploading = false;
      _uploadingPurpose = null;
      notifyListeners();
      return false;
    }
  }

  /// Upload profile picture immediately and store the URL
  Future<bool> uploadProfilePicture(dynamic file) async {
    _isUploading = true;
    _uploadingPurpose = 'profile_picture';
    notifyListeners();

    try {
      debugPrint('📤 Uploading profile picture immediately...');
      final viewUrl = await _gymService.uploadFile(file, 'profile_picture');

      if (viewUrl != null) {
        _profilePictureUrl = viewUrl;
        debugPrint('✅ Profile picture uploaded: $viewUrl');
        _isUploading = false;
        _uploadingPurpose = null;
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ Failed to upload profile picture');
        _isUploading = false;
        _uploadingPurpose = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error uploading profile picture: $e');
      _isUploading = false;
      _uploadingPurpose = null;
      notifyListeners();
      return false;
    }
  }

  /// Upload KYC document immediately and store the URL
  Future<bool> uploadKycDocument(String type, dynamic file) async {
    _isUploading = true;
    _uploadingPurpose = type;
    notifyListeners();

    try {
      debugPrint('📤 Uploading KYC document ($type) immediately...');
      debugPrint('📤 File type: ${file.runtimeType}');
      debugPrint('📤 File name: ${file is XFile ? file.name : file.toString().split('/').last}');
      
      final viewUrl = await _gymService.uploadFile(file, type);

      if (viewUrl != null) {
        _kycDocumentUrls[type] = viewUrl;
        debugPrint('✅ KYC document ($type) uploaded: $viewUrl');
        debugPrint('✅ Updated kycDocumentUrls: $_kycDocumentUrls');
        _isUploading = false;
        _uploadingPurpose = null;
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ Failed to upload KYC document ($type)');
        _isUploading = false;
        _uploadingPurpose = null;
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading KYC document ($type): $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _isUploading = false;
      _uploadingPurpose = null;
      notifyListeners();
      return false;
    }
  }

  /// Upload service image immediately (returns URL for caller to handle)
  Future<String?> uploadServiceImage(dynamic file) async {
    try {
      debugPrint('📤 Uploading service image immediately...');
      final viewUrl = await _gymService.uploadFile(file, 'service_image');

      if (viewUrl != null) {
        debugPrint('✅ Service image uploaded: $viewUrl');
        return viewUrl;
      } else {
        debugPrint('❌ Failed to upload service image');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading service image: $e');
      return null;
    }
  }

  /// Upload equipment image immediately (returns URL for caller to handle)
  Future<String?> uploadEquipmentImage(dynamic file) async {
    try {
      debugPrint('📤 Uploading equipment image immediately...');
      final viewUrl = await _gymService.uploadFile(file, 'equipment_image');

      if (viewUrl != null) {
        debugPrint('✅ Equipment image uploaded: $viewUrl');
        return viewUrl;
      } else {
        debugPrint('❌ Failed to upload equipment image');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error uploading equipment image: $e');
      return null;
    }
  }

  // ============ API METHODS ============

  /// Create gym profile - NO upload logic, just send URLs
  Future<bool> createGymProfile() async {
    _status = BusinessStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Build profile data with already-uploaded URLs
      final profileData = _buildGymProfileData();

      debugPrint('📤 Creating gym profile with data: $profileData');

      // Create gym profile
      final result = await _gymService.createGymProfile(profileData);

      if (result['success'] == true) {
        debugPrint('✅ Gym profile created successfully');

        // Fetch full profile
        await loadGymProfile();

        // Fetch initial transactions
        try {
          final result = await _customerService.getSubscriptions(
            type: 'all',
            status: 'confirmed',
          );
          if (result['success'] == true && result['data'] != null) {
            _initialTransactions =
                _customerService.parseSubscriptions(result['data']);
          }
        } catch (e) {
          debugPrint('⚠️ Could not fetch transactions: $e');
        }

        _status = BusinessStatus.success;
        notifyListeners();
        return true;
      } else {
        _status = BusinessStatus.error;
        _errorMessage = result['message'];
        debugPrint('❌ Failed to create gym profile: $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = BusinessStatus.error;
      _errorMessage = e.toString();
      debugPrint('❌ Error creating gym profile: $e');
      notifyListeners();
      return false;
    }
  }

  Business? _parseBusinessFromProfile(Map<String, dynamic> data) {
    try {
      return Business.fromApiResponse(data);
    } catch (e) {
      debugPrint('❌ Error parsing business from profile: $e');
      return null;
    }
  }

  /// Build gym profile data for API - URLs already uploaded
  Map<String, dynamic> _buildGymProfileData() {
    final data = <String, dynamic>{
      'business': {
        'name': _businessName,
        'email': _email,
        'about': _aboutUs,
      },
      'location': {
        'lat': _latitude,
        'lng': _longitude,
        'formatted_address': _formattedAddress,
      },
    };

    // Profile picture - already uploaded URL
    if (_profilePictureUrl != null) {
      data['profile_picture'] = [
        {
          's3_url': _profilePictureUrl,
          'url': _profilePictureUrl,
          'view_url': _profilePictureUrl,
          'image_url': _profilePictureUrl,
        }
      ];
      // For backward compatibility with older Admin/Customer panels
      data['profile_image'] = _profilePictureUrl;
      data['logo'] = _profilePictureUrl;
    }

    // Display images - already uploaded URLs
    if (_displayImageUrls.isNotEmpty) {
      data['display_images'] = _displayImageUrls.map((url) => {
            's3_url': url,
            'url': url,
            'view_url': url,
            'image_url': url,
          }).toList();
      // For backward compatibility with older Admin/Customer panels
      data['images'] = _displayImageUrls;
    }

    if (_displayVideoUrl != null) {
      data['display_video'] = [{'s3_url': _displayVideoUrl}];
    }

    // KYC documents - already uploaded URLs
    if (_kycDocumentUrls.isNotEmpty) {
      data['kyc_documents'] = _kycDocumentUrls.entries
          .map((e) => {'type': e.key, 's3_url': e.value})
          .toList();
    }

    // Address
    if (_address != null) {
      data['address'] = {
        'building_name': _address!.buildingName,
        'street': _address!.street,
        'locality': _address!.locality,
        'city': _address!.city,
        'state': _address!.state,
        'pincode': _address!.pincode,
        'country': _address!.country,
      };
    }

    // Business hours
    data['business_hours'] = {
      'mon': _dayHoursToJson(_businessHours.monday),
      'tue': _dayHoursToJson(_businessHours.tuesday),
      'wed': _dayHoursToJson(_businessHours.wednesday),
      'thu': _dayHoursToJson(_businessHours.thursday),
      'fri': _dayHoursToJson(_businessHours.friday),
      'sat': _dayHoursToJson(_businessHours.saturday),
      'sun': _dayHoursToJson(_businessHours.sunday),
    };

    // Services with images (already uploaded URLs)
    if (_services.isNotEmpty) {
      data['services'] = _services.map((s) {
        final serviceData = <String, dynamic>{
          'name': s.name,
          'description': s.description ?? '',
          'price': s.price,
          'price_unit': s.priceUnit ?? 'INR/session',
          'duration': s.duration ?? '60 mins',
        };
        if (s.images.isNotEmpty) {
          serviceData['images'] =
              s.images.map((url) => {'s3_url': url}).toList();
        }
        return serviceData;
      }).toList();
    }

    // Facilities
    if (_facilities.isNotEmpty) {
      data['facilities'] = _facilities
          .where((f) => f.isIncluded)
          .map((f) => {
                'name': f.name,
                'description': f.description ?? '',
                'included': f.isIncluded,
                'price': f.price,
                'unit': f.unit ?? 'INR',
              })
          .toList();
    }

    // Equipment with images (already uploaded URLs)
    if (_equipments.isNotEmpty) {
      data['equipment'] = _equipments.map((e) {
        final equipmentData = <String, dynamic>{
          'name': e.name,
        };
        if (e.images.isNotEmpty) {
          equipmentData['images'] =
              e.images.map((url) => {'s3_url': url}).toList();
        }
        return equipmentData;
      }).toList();
    }

    // Membership fees
    if (_membershipFee != null) {
      final fees = <Map<String, dynamic>>[];
      if (_membershipFee!.dailyFee != null) {
        fees.add({
          'type': 'Daily',
          'price': _membershipFee!.dailyFee,
          'discount': _membershipFee!.dailyDiscount ?? 0,
        });
      }
      if (_membershipFee!.weeklyFee != null) {
        fees.add({
          'type': 'Weekly',
          'price': _membershipFee!.weeklyFee,
          'discount': _membershipFee!.weeklyDiscount ?? 0,
        });
      }
      if (_membershipFee!.monthlyFee != null) {
        fees.add({
          'type': 'Monthly',
          'price': _membershipFee!.monthlyFee,
          'discount': _membershipFee!.monthlyDiscount ?? 0,
        });
      }
      if (_membershipFee!.quarterlyFee != null) {
        fees.add({
          'type': 'Quarterly',
          'price': _membershipFee!.quarterlyFee,
          'discount': _membershipFee!.quarterlyDiscount ?? 0,
        });
      }
      if (_membershipFee!.annualFee != null) {
        fees.add({
          'type': 'Annual',
          'price': _membershipFee!.annualFee,
          'discount': _membershipFee!.annualDiscount ?? 0,
        });
      }
      if (fees.isNotEmpty) {
        data['membership_fees'] = fees;
      }
    }

    return data;
  }

  Map<String, dynamic> _dayHoursToJson(DayHours hours) {
    if (!hours.isOpen) {
      return {'open': false};
    }
    return {
      'open': true,
      'slots': hours.slots.map((s) => s.toJson()).toList(),
    };
  }

  /// Load existing gym profile
  Future<void> loadGymProfile() async {
    _status = BusinessStatus.loading;
    notifyListeners();

    try {
      debugPrint('📥 Loading existing gym profile...');
      final result = await _gymService.getGymProfile();

      debugPrint('📥 Load Gym Profile Result: $result');

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        _gymProfileData = data;

        // Populate fields from API response
        _businessName = data['business']?['name'] ?? '';
        _email = data['business']?['email'] ?? '';
        _aboutUs = data['business']?['about'] ?? '';

        if (data['location'] != null) {
          _latitude = data['location']['lat']?.toDouble();
          _longitude = data['location']['lng']?.toDouble();
          _formattedAddress = data['location']['formatted_address'];
        }

        // Load display images (URLs from server)
        if (data['display_images'] != null) {
          _displayImageUrls = (data['display_images'] as List)
              .map((img) => img['s3_url'] as String)
              .toList();
        }

        // Load display video
        if (data['display_video'] != null &&
            (data['display_video'] as List).isNotEmpty) {
          _displayVideoUrl = data['display_video'][0]['s3_url'];
        }

        // Load profile picture (URL from server)
        if (data['profile_picture'] != null &&
            (data['profile_picture'] as List).isNotEmpty) {
          _profilePictureUrl = data['profile_picture'][0]['s3_url'];
        }

        // Load KYC documents (URLs from server)
        if (data['kyc_documents'] != null) {
          _kycDocumentUrls = {};
          for (final doc in (data['kyc_documents'] as List)) {
            final type = doc['type'] as String?;
            final url = doc['s3_url'] as String?;
            if (type != null && url != null) {
              _kycDocumentUrls[type] = url;
            }
          }
        }

        // Parse business model
        _business = _parseBusinessFromProfile(data);

        _status = BusinessStatus.success;
        debugPrint('✅ Gym profile loaded successfully');
      } else {
        _status = BusinessStatus.error;
        _errorMessage = result['message'];
        debugPrint('❌ Failed to load gym profile: $_errorMessage');
      }
    } catch (e) {
      _status = BusinessStatus.error;
      _errorMessage = e.toString();
      debugPrint('❌ Error loading gym profile: $e');
    }

    notifyListeners();
  }

  /// Update gym profile
  Future<bool> updateGymProfile(Map<String, dynamic> updateData) async {
    _status = BusinessStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('📤 Updating gym profile with data: $updateData');
      final result = await _gymService.updateGymProfile(updateData);

      debugPrint('📥 Update Gym Profile Result: $result');

      if (result['success'] == true) {
        _status = BusinessStatus.success;
        debugPrint('✅ Gym profile updated successfully');
        notifyListeners();
        return true;
      } else {
        _status = BusinessStatus.error;
        _errorMessage = result['message'];
        debugPrint('❌ Failed to update gym profile: $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = BusinessStatus.error;
      _errorMessage = e.toString();
      debugPrint('❌ Error updating gym profile: $e');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _status = BusinessStatus.initial;
    _errorMessage = null;
    _business = null;
    _businessName = '';
    _aboutUs = '';
    _displayImageUrls = [];
    _displayVideoUrl = null;
    _profilePictureUrl = null;
    _address = null;
    _latitude = null;
    _longitude = null;
    _formattedAddress = null;
    _businessHours = BusinessHours.defaultHours();
    _services = [];
    _facilities = [];
    _equipments = [];
    _membershipFee = null;
    _kycDocumentUrls = {};
    _gymProfileData = null;
    _initialTransactions = null;
    notifyListeners();
  }
}
