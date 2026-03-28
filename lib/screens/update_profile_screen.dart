import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/constants.dart';
import '../core/network/api_client.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/utils.dart';
import '../models/models.dart';
import '../providers/home_provider.dart';
import '../services/gym_service.dart';
import 'home_screen.dart';
import 'widgets/business_hours_section.dart';
import 'widgets/add_service_sheet.dart';
import 'widgets/facilities_sheet.dart';
import 'widgets/equipments_sheet.dart';
import 'widgets/membership_sheet.dart';

enum ExpandedSection {
  none,
  displayImages,
  businessHours,
  services,
  facilities,
  equipments,
  membership
}

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _aboutController = TextEditingController();
  final GymService _gymService = GymService();
  final ImagePicker _picker = ImagePicker();

  // Profile picture
  XFile? _selectedProfileImage;
  Uint8List? _selectedProfileImageBytes;
  String? _currentProfilePictureUrl;

  // Display images
  List<String> _existingDisplayImages = [];
  List<XFile> _newDisplayImages = [];
  final Map<String, Uint8List> _newDisplayImageBytes = {};
  List<String> _removedDisplayImages = [];

  // Display video
  XFile? _newDisplayVideo;
  String? _existingDisplayVideoUrl;
  bool _isUploadingVideo = false;

  // Services data
  BusinessHours _businessHours = BusinessHours.defaultHours();
  List<Service> _services = [];
  List<Facility> _facilities = [];
  List<Equipment> _equipments = [];
  MembershipFee? _membershipFee;

  // Original data for comparison
  String? _originalBusinessName;
  String? _originalAbout;

  // State
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isUploadingImage = false;

  BusinessHours _originalBusinessHours = BusinessHours.defaultHours();
  List<Service> _originalServices = [];
  List<Facility> _originalFacilities = [];
  List<Equipment> _originalEquipments = [];
  MembershipFee? _originalMembershipFee;

  ExpandedSection _expandedSection = ExpandedSection.none;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  /// Toggle section expansion
  void _toggleSection(ExpandedSection section) {
    setState(() {
      _expandedSection =
          _expandedSection == section ? ExpandedSection.none : section;
    });
  }

  /// Load current profile data
  Future<void> _loadCurrentProfile() async {
    setState(() => _isLoadingData = true);

    try {
      final homeProvider = context.read<HomeProvider>();

      // Ensure data is loaded
      if (homeProvider.gymProfileData == null) {
        await homeProvider.loadData();
      }

      if (homeProvider.gymProfileData != null) {
        final profileData = homeProvider.gymProfileData!;
        debugPrint('📦 Profile data: $profileData');

        // Business name
        if (profileData['business'] != null &&
            profileData['business']['name'] != null) {
          _businessNameController.text = profileData['business']['name'];
          _originalBusinessName = profileData['business']['name'];
        }

        // About/Description
        if (profileData['business'] != null &&
            profileData['business']['about'] != null) {
          _aboutController.text = profileData['business']['about'];
          _originalAbout = profileData['business']['about'];
        }

        // Profile picture
        if (profileData['profile_picture'] != null &&
            profileData['profile_picture'] is List &&
            profileData['profile_picture'].isNotEmpty) {
          _currentProfilePictureUrl =
              profileData['profile_picture'][0]['s3_url'];
        }

        // Display images
        if (profileData['display_images'] != null &&
            profileData['display_images'] is List) {
          _existingDisplayImages = (profileData['display_images'] as List)
              .map((img) => img['s3_url']?.toString() ?? '')
              .where((url) => url.isNotEmpty)
              .toList();
          debugPrint(
              '📸 Loaded ${_existingDisplayImages.length} display images');
        }

        // Display video — from backend if available, else from local cache
        if (profileData['display_video'] != null &&
            (profileData['display_video'] as List).isNotEmpty) {
          _existingDisplayVideoUrl =
              profileData['display_video'][0]['s3_url']?.toString();
          debugPrint('🎬 Loaded display video from backend: $_existingDisplayVideoUrl');
          // Keep local cache in sync
          if (_existingDisplayVideoUrl != null) {
            await ApiClient.saveDisplayVideoUrl(_existingDisplayVideoUrl!);
          }
        } else {
          // Backend doesn’t return display_video yet — fall back to local cache
          _existingDisplayVideoUrl = await ApiClient.getDisplayVideoUrl();
          debugPrint('🎬 Loaded display video from local cache: $_existingDisplayVideoUrl');
        }

        // Business Hours
        if (profileData['business_hours'] != null &&
            profileData['business_hours'] is Map) {
          _businessHours = BusinessHours.fromApiResponse(
              profileData['business_hours'] as Map<String, dynamic>);
          _originalBusinessHours = _businessHours;
        } else {
          _businessHours = BusinessHours.defaultHours();
          _originalBusinessHours = _businessHours;
        }

        // Services
        if (profileData['services'] != null &&
            profileData['services'] is List) {
          _services = (profileData['services'] as List)
              .map((s) => Service(
                    name: s['name'] ?? '',
                    description: s['description'] ?? '',
                    price: s['price'] != null
                        ? (s['price'] as num).toDouble()
                        : 0.0,
                  ))
              .toList();
          _originalServices = List.from(_services);
        }

        // Facilities
        if (profileData['facilities'] != null &&
            profileData['facilities'] is List) {
          _facilities = (profileData['facilities'] as List)
              .map((f) => Facility(
                    name: f['name'] ?? '',
                    price: (f['price_per_hour'] ?? 0).toDouble(),
                  ))
              .toList();
          _originalFacilities = List.from(_facilities);
        }

        // Equipments
        if (profileData['equipments'] != null &&
            profileData['equipments'] is List) {
          _equipments = (profileData['equipments'] as List)
              .map((e) => Equipment(name: e['name'] ?? ''))
              .toList();
          _originalEquipments = List.from(_equipments);
        }

        // Membership Fee
        if (profileData['membership_fees'] != null &&
            profileData['membership_fees'] is List) {
          final feesList = profileData['membership_fees'] as List;
          double? dailyFee, dailyDiscount, weeklyFee, weeklyDiscount, monthlyFee, monthlyDiscount, quarterlyFee, quarterlyDiscount, annualFee, annualDiscount;
          for (final fee in feesList) {
            if (fee is Map) {
              final typeRaw = fee['type']?.toString().toLowerCase();
              final feeAmount = (fee['price'] ?? fee['fee'] ?? 0).toDouble();
              final discount = (fee['discount'] ?? 0).toDouble();
              switch (typeRaw) {
                case 'daily':
                  dailyFee = feeAmount;
                  dailyDiscount = discount;
                  break;
                case 'weekly':
                  weeklyFee = feeAmount;
                  weeklyDiscount = discount;
                  break;
                case 'monthly':
                  monthlyFee = feeAmount;
                  monthlyDiscount = discount;
                  break;
                case 'quarterly':
                  quarterlyFee = feeAmount;
                  quarterlyDiscount = discount;
                  break;
                case 'annual':
                case 'yearly':
                  annualFee = feeAmount;
                  annualDiscount = discount;
                  break;
              }
            }
          }
          _membershipFee = MembershipFee(
            dailyFee: dailyFee,
            dailyDiscount: dailyDiscount,
            weeklyFee: weeklyFee,
            weeklyDiscount: weeklyDiscount,
            monthlyFee: monthlyFee,
            monthlyDiscount: monthlyDiscount,
            quarterlyFee: quarterlyFee,
            quarterlyDiscount: quarterlyDiscount,
            annualFee: annualFee,
            annualDiscount: annualDiscount,
          );
          _originalMembershipFee = _membershipFee;
        }
      }

      setState(() => _isLoadingData = false);
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
      setState(() => _isLoadingData = false);
      if (mounted) {
        _showSnackbar('Failed to load profile data', isError: true);
      }
    }
  }

  /// Parse business hours from API response
  Map<String, DayHours> _parseBusinessHours(Map<String, dynamic> hoursData) {
    Map<String, DayHours> result = {};
    final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

    for (final day in days) {
      if (hoursData[day] != null) {
        final dayData = hoursData[day];
        List<TimeSlot> slotsList = [];
        if (dayData['slots'] != null && dayData['slots'] is List) {
          slotsList = (dayData['slots'] as List).map((e) => TimeSlot.fromApiResponse(e)).toList();
        } else if (dayData['from'] != null && dayData['to'] != null) {
          slotsList = [TimeSlot(label: 'Default', from: dayData['from'], to: dayData['to'])];
        } else {
          slotsList = [TimeSlot(label: 'Morning', from: '09:00 AM', to: '09:00 PM')];
        }
        result[day] = DayHours(
          isOpen: dayData['open'] ?? false,
          slots: slotsList,
        );
      } else {
        result[day] = DayHours(
            isOpen: day != 'sun', slots: [TimeSlot(label: 'Morning', from: '09:00 AM', to: '09:00 PM')]);
      }
    }

    return result;
  }

  /// Get default business hours
  Map<String, DayHours> _getDefaultBusinessHours() {
    return {
      'mon': DayHours(isOpen: true, slots: [TimeSlot(label: 'Morning', from: '09:00 AM', to: '09:00 PM')]),
      'tue': DayHours(isOpen: true, slots: [TimeSlot(label: 'Morning', from: '09:00 AM', to: '09:00 PM')]),
      'wed': DayHours(isOpen: true, slots: [TimeSlot(label: 'Morning', from: '09:00 AM', to: '09:00 PM')]),
      'thu': DayHours(isOpen: true, slots: [TimeSlot(label: 'Morning', from: '09:00 AM', to: '09:00 PM')]),
      'fri': DayHours(isOpen: true, slots: [TimeSlot(label: 'Morning', from: '09:00 AM', to: '09:00 PM')]),
      'sat': DayHours(isOpen: true, slots: [TimeSlot(label: 'Morning', from: '09:00 AM', to: '09:00 PM')]),
      'sun': DayHours(isOpen: false, slots: [TimeSlot(label: 'Morning', from: '09:00 AM', to: '09:00 PM')]),
    };
  }

  /// Pick profile image
  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedProfileImage = image;
          _selectedProfileImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      _showSnackbar('Failed to pick image', isError: true);
    }
  }

  /// Pick display images
  Future<void> _pickDisplayImages() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(imageQuality: 80);

      if (files.isNotEmpty && mounted) {
        for (final f in files) {
          final bytes = await f.readAsBytes();
          setState(() {
            _newDisplayImages.add(f);
            _newDisplayImageBytes[f.name] = bytes;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error picking images: $e');
      _showSnackbar('Failed to pick images', isError: true);
    }
  }

  /// Pick display video
  Future<void> _pickDisplayVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
      if (video != null && mounted) {
        setState(() {
          _newDisplayVideo = video;
        });
      }
    } catch (e) {
      debugPrint('❌ Error picking video: $e');
      _showSnackbar('Failed to pick video', isError: true);
    }
  }

  /// Remove display video
  void _removeDisplayVideo() {
    setState(() {
      _newDisplayVideo = null;
      _existingDisplayVideoUrl = null;
    });
    // Clear local cache too
    ApiClient.clearDisplayVideoUrl();
  }

  /// Remove existing display image
  void _removeExistingDisplayImage(int index) {
    setState(() {
      final url = _existingDisplayImages[index];
      _removedDisplayImages.add(url);
      _existingDisplayImages.removeAt(index);
    });
  }

  /// Remove new display image
  void _removeNewDisplayImage(int index) {
    setState(() {
      _newDisplayImages.removeAt(index);
    });
  }

  /// Upload file to S3
  Future<String?> _uploadFile(dynamic file, String purpose) async {
    try {
      final s3Url = await _gymService.uploadFile(file, purpose);
      return s3Url;
    } catch (e) {
      debugPrint('❌ Error uploading file: $e');
      return null;
    }
  }

  /// Update profile
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> updateData = {};

      // Check business name change
      final newName = _businessNameController.text.trim();
      if (newName != _originalBusinessName) {
        updateData['business'] = {'name': newName};
      }

      // Check about change
      final newAbout = _aboutController.text.trim();
      if (newAbout != _originalAbout) {
        if (updateData['business'] == null) {
          updateData['business'] = {};
        }
        updateData['business']['about'] = newAbout;
      }

      // Upload profile image if selected
      if (_selectedProfileImage != null) {
        final profileImageUrl =
            await _uploadFile(_selectedProfileImage!, 'profile_picture');
        if (profileImageUrl != null) {
          updateData['profile_picture'] = [
            {'s3_url': profileImageUrl}
          ];
        } else {
          setState(() => _isLoading = false);
          _showSnackbar('Failed to upload profile picture', isError: true);
          return;
        }
      }

      // Upload new display images and build display_images array
      if (_newDisplayImages.isNotEmpty || _removedDisplayImages.isNotEmpty) {
        List<Map<String, String>> displayImages = [];

        // Add existing images that weren't removed
        for (final url in _existingDisplayImages) {
          displayImages.add({'s3_url': url});
        }

        // Upload and add new images
        for (final file in _newDisplayImages) {
          final url = await _uploadFile(file, 'display_image');
          if (url != null) {
            displayImages.add({'s3_url': url});
          }
        }

        updateData['display_images'] = displayImages;
      }

      // Upload display video if a new one was selected
      if (_newDisplayVideo != null) {
        setState(() => _isUploadingVideo = true);
        final videoUrl = await _uploadFile(_newDisplayVideo!, 'display_video');
        setState(() => _isUploadingVideo = false);
        if (videoUrl != null) {
          updateData['display_video'] = [{'s3_url': videoUrl}];
          // Save to local cache so it persists even though backend doesn't return it yet
          await ApiClient.saveDisplayVideoUrl(videoUrl);
        } else {
          setState(() => _isLoading = false);
          _showSnackbar('Failed to upload video', isError: true);
          return;
        }
      } else if (_existingDisplayVideoUrl == null) {
        // Explicitly cleared
        updateData['display_video'] = [];
      }

      // Check business hours change
      if (_hasBusinessHoursChanged()) {
        updateData['business_hours'] = _businessHoursToJson();
      }

      if (_hasServicesChanged()) {
        updateData['services'] = _services
            .map((s) => {
                  'name': s.name,
                  'description': s.description,
                  'price': s.price,
                  'price_unit': s.priceUnit,
                  'duration': s.duration,
                  'images': s.images,
                  'time_slots': s.timeSlots.map((ts) => ts.toJson()).toList(),
                })
            .toList();
      }

      // Check facilities change
      if (_hasFacilitiesChanged()) {
        updateData['facilities'] = _facilities
            .where((f) => f.isAvailable)
            .map((f) => {
                  'name': f.name,
                  'price_per_hour': f.price,
                })
            .toList();
      }

      // Check equipments change
      if (_hasEquipmentsChanged()) {
        updateData['equipments'] =
            _equipments.map((e) => {'name': e.name}).toList();
      }

      // Check membership fee change
      if (_hasMembershipFeeChanged()) {
        debugPrint('📝 Membership fee changed, adding to update data');
        List<Map<String, dynamic>> fees = [];
        if ((_membershipFee?.dailyFee ?? 0) > 0) {
          fees.add({
            'type': 'Daily',
            'price': _membershipFee!.dailyFee,
            'discount': _membershipFee!.dailyDiscount ?? 0,
          });
        }
        if ((_membershipFee?.weeklyFee ?? 0) > 0) {
          fees.add({
            'type': 'Weekly',
            'price': _membershipFee!.weeklyFee,
            'discount': _membershipFee!.weeklyDiscount ?? 0,
          });
        }
        if ((_membershipFee?.monthlyFee ?? 0) > 0) {
          fees.add({
            'type': 'Monthly',
            'price': _membershipFee!.monthlyFee,
            'discount': _membershipFee!.monthlyDiscount ?? 0,
          });
        }
        if ((_membershipFee?.quarterlyFee ?? 0) > 0) {
          fees.add({
            'type': 'Quarterly',
            'price': _membershipFee!.quarterlyFee,
            'discount': _membershipFee!.quarterlyDiscount ?? 0,
          });
        }
        if ((_membershipFee?.annualFee ?? 0) > 0) {
          fees.add({
            'type': 'Annual',
            'price': _membershipFee!.annualFee,
            'discount': _membershipFee!.annualDiscount ?? 0,
          });
        }
        updateData['membership_fees'] = fees;
      } else {
        debugPrint('📝 Membership fee not changed');
      }

      // If nothing changed
      if (updateData.isEmpty) {
        setState(() => _isLoading = false);
        _showSnackbar('No changes to save', isError: false);
        return;
      }

      debugPrint('📦 Update data: $updateData');

      // Call update API
      final result = await _gymService.updateGymProfile(updateData);

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showSnackbar(result['message'] ?? 'Profile updated successfully',
            isError: false);

        // Reload home data
        if (mounted) {
          await context.read<HomeProvider>().loadData();
        }

        // Navigate back to home screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        _showSnackbar(result['message'] ?? 'Failed to update profile',
            isError: true);
      }
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      setState(() => _isLoading = false);
      _showSnackbar('Error updating profile: $e', isError: true);
    }
  }

  /// Convert business hours to JSON format
  Map<String, dynamic> _businessHoursToJson() {
    return _businessHours.toJson();
  }

  /// Check if business hours changed
  bool _hasBusinessHoursChanged() {
    for (int i = 0; i < 7; i++) {
      final current = _businessHours.getDayHours(i);
      final original = _originalBusinessHours.getDayHours(i);
      if (current.isOpen != original.isOpen ||
          current.slots.length != original.slots.length) {
        return true;
      }
      for (int j = 0; j < current.slots.length; j++) {
        if (current.slots[j].label != original.slots[j].label ||
            current.slots[j].from != original.slots[j].from ||
            current.slots[j].to != original.slots[j].to) {
          return true;
        }
      }
    }
    return false;
  }

  /// Check if services changed
  bool _hasServicesChanged() {
    if (_originalServices == null) return _services.isNotEmpty;
    if (_services.length != _originalServices!.length) return true;
    for (int i = 0; i < _services.length; i++) {
      if (_services[i].name != _originalServices![i].name ||
          _services[i].description != _originalServices![i].description) {
        return true;
      }
    }
    return false;
  }

  /// Check if facilities changed
  bool _hasFacilitiesChanged() {
    if (_originalFacilities == null) return _facilities.isNotEmpty;
    if (_facilities.length != _originalFacilities!.length) return true;
    for (int i = 0; i < _facilities.length; i++) {
      if (_facilities[i].name != _originalFacilities![i].name ||
          _facilities[i].isAvailable != _originalFacilities![i].isAvailable ||
          _facilities[i].price != _originalFacilities![i].price) {
        return true;
      }
    }
    return false;
  }

  /// Check if equipments changed
  bool _hasEquipmentsChanged() {
    if (_originalEquipments == null) return _equipments.isNotEmpty;
    if (_equipments.length != _originalEquipments!.length) return true;
    for (int i = 0; i < _equipments.length; i++) {
      if (_equipments[i].name != _originalEquipments![i].name) {
        return true;
      }
    }
    return false;
  }

  /// Check if membership fee changed
  bool _hasMembershipFeeChanged() {
    if (_originalMembershipFee == null && _membershipFee == null) {
      debugPrint('📝 Membership fee: both null, no change');
      return false;
    }
    if (_originalMembershipFee == null || _membershipFee == null) {
      debugPrint('📝 Membership fee: one is null, changed');
      return true;
    }
    bool changed = _membershipFee!.dailyFee != _originalMembershipFee!.dailyFee ||
        _membershipFee!.dailyDiscount != _originalMembershipFee!.dailyDiscount ||
        _membershipFee!.weeklyFee != _originalMembershipFee!.weeklyFee ||
        _membershipFee!.weeklyDiscount != _originalMembershipFee!.weeklyDiscount ||
        _membershipFee!.monthlyFee != _originalMembershipFee!.monthlyFee ||
        _membershipFee!.monthlyDiscount != _originalMembershipFee!.monthlyDiscount ||
        _membershipFee!.quarterlyFee != _originalMembershipFee!.quarterlyFee ||
        _membershipFee!.quarterlyDiscount != _originalMembershipFee!.quarterlyDiscount ||
        _membershipFee!.annualFee != _originalMembershipFee!.annualFee ||
        _membershipFee!.annualDiscount != _originalMembershipFee!.annualDiscount;
    debugPrint('📝 Membership fee changed: $changed');
    debugPrint('📝 Original: $_originalMembershipFee');
    debugPrint('📝 Current: $_membershipFee');
    return changed;
  }

  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  /// Update day hours by index (0=Monday, 6=Sunday)
  void _updateDayHours(int dayIndex, DayHours hours) {
    setState(() {
      switch (dayIndex) {
        case 0:
          _businessHours = _businessHours.copyWith(monday: hours);
          break;
        case 1:
          _businessHours = _businessHours.copyWith(tuesday: hours);
          break;
        case 2:
          _businessHours = _businessHours.copyWith(wednesday: hours);
          break;
        case 3:
          _businessHours = _businessHours.copyWith(thursday: hours);
          break;
        case 4:
          _businessHours = _businessHours.copyWith(friday: hours);
          break;
        case 5:
          _businessHours = _businessHours.copyWith(saturday: hours);
          break;
        case 6:
          _businessHours = _businessHours.copyWith(sunday: hours);
          break;
      }
    });
  }

  /// Show add service sheet
  void _showAddServiceSheet({int? editIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(ResponsiveHelper.screenWidth * 0.06)),
      ),
      builder: (context) => AddServiceSheet(
        service: editIndex != null ? _services[editIndex] : null,
        onSave: (service) {
          setState(() {
            if (editIndex != null) {
              _services[editIndex] = service;
            } else {
              _services.add(service);
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Show facilities sheet
  void _showFacilitiesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(ResponsiveHelper.screenWidth * 0.06)),
      ),
      builder: (context) => FacilitiesSheet(
        selectedFacilities: _facilities,
        onSave: (facilities) {
          setState(() {
            _facilities = facilities;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Show equipments sheet
  void _showEquipmentsSheet({int? editIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(ResponsiveHelper.screenWidth * 0.06)),
      ),
      builder: (context) => EquipmentsSheet(
        equipment: editIndex != null ? _equipments[editIndex] : null,
        onSave: (equipment) {
          setState(() {
            if (editIndex != null) {
              _equipments[editIndex] = equipment;
            } else {
              _equipments.add(equipment);
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Show membership sheet
  void _showMembershipSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(ResponsiveHelper.screenWidth * 0.06)),
      ),
      builder: (context) => MembershipSheet(
        membershipFee: _membershipFee,
        onSave: (fee) {
          setState(() {
            _membershipFee = fee;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final screenWidth = ResponsiveHelper.screenWidth;
    final screenHeight = ResponsiveHelper.screenHeight;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Update Profile', style: AppTextStyles.heading4),
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Picture Section
                          Center(
                              child: _buildProfilePictureSection(
                                  screenWidth, screenHeight)),
                          SizedBox(height: screenHeight * 0.03),

                          // Business Name
                          Text('Business Name',
                              style: AppTextStyles.labelMedium),
                          SizedBox(height: screenHeight * 0.01),
                          CustomTextField(
                            controller: _businessNameController,
                            hintText: 'Enter your business name',
                            enabled: !_isLoading,
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          // About/Description
                          Text('About Your Business',
                              style: AppTextStyles.labelMedium),
                          SizedBox(height: screenHeight * 0.01),
                          CustomTextField(
                            controller: _aboutController,
                            hintText: 'Tell us about your gym...',
                            maxLines: 4,
                            enabled: !_isLoading,
                          ),
                          SizedBox(height: screenHeight * 0.02),

                          // Display Images Section
                          _buildSection(
                            ExpandedSection.displayImages,
                            'Display Images',
                            screenWidth,
                            screenHeight,
                            trailing: _addButton(
                                () => _pickDisplayImages(), screenWidth),
                            child: _buildDisplayImagesSection(
                                screenWidth, screenHeight),
                          ),
                          SizedBox(height: screenHeight * 0.015),

                          // Business Hours Section
                          _buildSection(
                            ExpandedSection.businessHours,
                            'Business Hours',
                            screenWidth,
                            screenHeight,
                            child: BusinessHoursSection(
                              businessHours: _businessHours,
                              onUpdate: _updateDayHours,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.015),

                          // Services Section
                          _buildSection(
                            ExpandedSection.services,
                            'Services',
                            screenWidth,
                            screenHeight,
                            trailing: _addButton(
                                () => _showAddServiceSheet(), screenWidth),
                            child: _buildServicesList(screenWidth),
                          ),
                          SizedBox(height: screenHeight * 0.015),

                          // Facilities Section
                          _buildSection(
                            ExpandedSection.facilities,
                            'Facilities',
                            screenWidth,
                            screenHeight,
                            trailing: _addButton(
                                () => _showFacilitiesSheet(), screenWidth),
                            child: _buildFacilitiesList(screenWidth),
                          ),
                          SizedBox(height: screenHeight * 0.015),

                          // Equipments Section
                          _buildSection(
                            ExpandedSection.equipments,
                            'Equipments',
                            screenWidth,
                            screenHeight,
                            trailing: _addButton(
                                () => _showEquipmentsSheet(), screenWidth),
                            child: _buildEquipmentsList(screenWidth),
                          ),
                          SizedBox(height: screenHeight * 0.015),

                          // Membership Fee Section
                          _buildSection(
                            ExpandedSection.membership,
                            'Membership Fee',
                            screenWidth,
                            screenHeight,
                            trailing: _addButton(
                                () => _showMembershipSheet(), screenWidth),
                            child: _buildMembershipInfo(screenWidth),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
                // Update Button
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: SafeArea(
                    top: false,
                    child: PrimaryButton(
                      text: _isUploadingVideo ? 'Uploading video...' : 'Update Profile',
                      onPressed: (_isLoading || _isUploadingVideo) ? null : _updateProfile,
                      isLoading: _isLoading || _isUploadingVideo,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfilePictureSection(double screenWidth, double screenHeight) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: screenWidth * 0.3,
              height: screenWidth * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardBackground,
                border: Border.all(color: AppColors.primaryGreen, width: 3),
              ),
              child: ClipOval(
                child: _selectedProfileImageBytes != null
                    ? Image.memory(_selectedProfileImageBytes!, fit: BoxFit.cover)
                    : _currentProfilePictureUrl != null
                        ? CachedNetworkImage(
                            imageUrl: _currentProfilePictureUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryGreen),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.fitness_center,
                              color: AppColors.primaryGreen,
                              size: screenWidth * 0.12,
                            ),
                          )
                        : Icon(
                            Icons.fitness_center,
                            color: AppColors.primaryGreen,
                            size: screenWidth * 0.12,
                          ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _isLoading ? null : _pickProfileImage,
                child: Container(
                  width: screenWidth * 0.09,
                  height: screenWidth * 0.09,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: AppColors.buttonText,
                    size: screenWidth * 0.045,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight * 0.015),
        Text(
          'Tap to change profile picture',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSection(
    ExpandedSection section,
    String title,
    double screenWidth,
    double screenHeight, {
    Widget? trailing,
    required Widget child,
  }) {
    final isExpanded = _expandedSection == section;

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(section),
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontSize: ResponsiveHelper.sp(15),
                      ),
                    ),
                  ),
                  if (trailing != null && !isExpanded) ...[
                    trailing,
                    SizedBox(width: screenWidth * 0.02),
                  ],
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textPrimary,
                      size: screenWidth * 0.06,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(height: 1, color: AppColors.inputBorder.withOpacity(0.5)),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  Widget _addButton(VoidCallback onTap, double screenWidth) => GestureDetector(
        onTap: onTap,
        child: Text(
          '+Add',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primaryGreen,
            fontSize: ResponsiveHelper.sp(14),
          ),
        ),
      );

  Widget _buildDisplayImagesSection(double screenWidth, double screenHeight) {
    final totalImages =
        _existingDisplayImages.length + _newDisplayImages.length;

    if (totalImages == 0 && _existingDisplayVideoUrl == null && _newDisplayVideo == null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.image_outlined,
                color: AppColors.textSecondary, size: screenWidth * 0.1),
            SizedBox(height: screenHeight * 0.01),
            Text(
              'No display images or video',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: screenHeight * 0.01),
            _addButton(() => _pickDisplayImages(), screenWidth),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing images
        if (_existingDisplayImages.isNotEmpty) ...[
          Text('Existing Images',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          SizedBox(height: screenHeight * 0.01),
          Wrap(
            spacing: screenWidth * 0.02,
            runSpacing: screenWidth * 0.02,
            children: _existingDisplayImages.asMap().entries.map((entry) {
              return _buildImageThumbnail(
                imageUrl: entry.value,
                onRemove: () => _removeExistingDisplayImage(entry.key),
                screenWidth: screenWidth,
              );
            }).toList(),
          ),
        ],

        // New images
        if (_newDisplayImages.isNotEmpty) ...[
          SizedBox(height: screenHeight * 0.015),
          Text('New Images',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          SizedBox(height: screenHeight * 0.01),
          Wrap(
            spacing: screenWidth * 0.02,
            runSpacing: screenWidth * 0.02,
            children: _newDisplayImages.asMap().entries.map((entry) {
              return _buildImageThumbnail(
                imageFile: entry.value,
                onRemove: () => _removeNewDisplayImage(entry.key),
                screenWidth: screenWidth,
              );
            }).toList(),
          ),
        ],

        SizedBox(height: screenHeight * 0.015),
        // Add Images button
        _addButton(() => _pickDisplayImages(), screenWidth),

        SizedBox(height: screenHeight * 0.02),

        // ── Display Video ──
        Row(
          children: [
            Icon(Icons.videocam_outlined,
                color: AppColors.textSecondary, size: screenWidth * 0.045),
            SizedBox(width: screenWidth * 0.02),
            Text('Display Video',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
        SizedBox(height: screenHeight * 0.01),

        if (_existingDisplayVideoUrl != null || _newDisplayVideo != null) ...
          [
            Container(
              height: screenHeight * 0.07,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  SizedBox(width: screenWidth * 0.03),
                  Icon(Icons.video_file,
                      color: AppColors.primaryGreen, size: screenWidth * 0.07),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Text(
                      _newDisplayVideo != null
                          ? _newDisplayVideo!.name
                          : 'Existing video',
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: AppColors.error, size: screenWidth * 0.05),
                    onPressed: _removeDisplayVideo,
                  ),
                ],
              ),
            ),
          ]
        else ...
          [
            GestureDetector(
              onTap: _pickDisplayVideo,
              child: Container(
                height: screenHeight * 0.07,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.5),
                      style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: AppColors.primaryGreen, size: screenWidth * 0.05),
                    SizedBox(width: screenWidth * 0.02),
                    Text('Upload Video (max 30s)',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryGreen)),
                  ],
                ),
              ),
            ),
          ],
      ],
    );
  }

  Widget _buildImageThumbnail({
    String? imageUrl,
    XFile? imageFile,
    required VoidCallback onRemove,
    required double screenWidth,
  }) {
    return Stack(
      children: [
        Container(
          width: screenWidth * 0.2,
          height: screenWidth * 0.2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            child: imageFile != null
                ? Image.memory(
                    _newDisplayImageBytes[imageFile.name] ?? Uint8List(0),
                    fit: BoxFit.cover,
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.inputBackground,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryGreen),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.inputBackground,
                      child: const Icon(Icons.broken_image,
                          color: AppColors.textSecondary),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: screenWidth * 0.05,
              height: screenWidth * 0.05,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: screenWidth * 0.03,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesList(double screenWidth) {
    if (_services.isEmpty) {
      return Center(
          child: _addButton(() => _showAddServiceSheet(), screenWidth));
    }
    return Column(
      children: [
        ..._services.asMap().entries.map((e) => _serviceItem(
              e.value,
              () => _showAddServiceSheet(editIndex: e.key),
              () {
                setState(() => _services.removeAt(e.key));
              },
              screenWidth,
            )),
        SizedBox(height: screenWidth * 0.02),
        Align(
          alignment: Alignment.centerLeft,
          child: _addButton(() => _showAddServiceSheet(), screenWidth),
        ),
      ],
    );
  }

  Widget _serviceItem(Service service, VoidCallback onEdit,
          VoidCallback onRemove, double screenWidth) =>
      Padding(
        padding: EdgeInsets.only(bottom: screenWidth * 0.02),
        child: Row(
          children: [
            Icon(Icons.check,
                color: AppColors.primaryGreen, size: screenWidth * 0.04),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: Text(
                service.name,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontSize: ResponsiveHelper.sp(14)),
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, size: screenWidth * 0.045),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: screenWidth * 0.045, color: AppColors.error),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );

  Widget _buildFacilitiesList(double screenWidth) {
    final active = _facilities.where((f) => f.isAvailable).toList();
    if (active.isEmpty) {
      return Center(
          child: _addButton(() => _showFacilitiesSheet(), screenWidth));
    }
    return Column(
      children: [
        ...active.map((f) => Padding(
              padding: EdgeInsets.only(bottom: screenWidth * 0.02),
              child: Row(
                children: [
                  Text(
                    '${f.name}  ₹${f.price.toInt()}/hr',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontSize: ResponsiveHelper.sp(14)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.edit, size: screenWidth * 0.045),
                    onPressed: () => _showFacilitiesSheet(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )),
        SizedBox(height: screenWidth * 0.02),
        Align(
          alignment: Alignment.centerLeft,
          child: _addButton(() => _showFacilitiesSheet(), screenWidth),
        ),
      ],
    );
  }

  Widget _buildEquipmentsList(double screenWidth) {
    if (_equipments.isEmpty) {
      return Center(
          child: _addButton(() => _showEquipmentsSheet(), screenWidth));
    }
    return Column(
      children: [
        ..._equipments.asMap().entries.map((e) => Padding(
              padding: EdgeInsets.only(bottom: screenWidth * 0.02),
              child: Row(
                children: [
                  Text(
                    e.value.name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontSize: ResponsiveHelper.sp(14)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.edit, size: screenWidth * 0.045),
                    onPressed: () => _showEquipmentsSheet(editIndex: e.key),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: screenWidth * 0.045, color: AppColors.error),
                    onPressed: () {
                      setState(() => _equipments.removeAt(e.key));
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )),
        SizedBox(height: screenWidth * 0.02),
        Align(
          alignment: Alignment.centerLeft,
          child: _addButton(() => _showEquipmentsSheet(), screenWidth),
        ),
      ],
    );
  }

  Widget _buildMembershipInfo(double screenWidth) {
    final fee = _membershipFee;
    if (fee == null) {
      return Center(
          child: _addButton(() => _showMembershipSheet(), screenWidth));
    }
    return Column(
      children: [
        if (fee.dailyFee != null && fee.dailyFee! > 0)
          _feeRow('Daily Fee', fee.dailyFee!, fee.dailyDiscount, screenWidth),
        if (fee.weeklyFee != null && fee.weeklyFee! > 0)
          _feeRow(
              'Weekly Fee', fee.weeklyFee!, fee.weeklyDiscount, screenWidth),
        if (fee.monthlyFee != null && fee.monthlyFee! > 0)
          _feeRow(
              'Monthly Fee', fee.monthlyFee!, fee.monthlyDiscount, screenWidth),
        if (fee.quarterlyFee != null && fee.quarterlyFee! > 0)
          _feeRow('Quarterly Fee', fee.quarterlyFee!, fee.quarterlyDiscount,
              screenWidth),
        if (fee.annualFee != null && fee.annualFee! > 0)
          _feeRow(
              'Yearly Fee', fee.annualFee!, fee.annualDiscount, screenWidth),
        SizedBox(height: screenWidth * 0.02),
        Align(
          alignment: Alignment.centerLeft,
          child: _addButton(() => _showMembershipSheet(), screenWidth),
        ),
      ],
    );
  }

  Widget _feeRow(
          String label, double fee, double? discount, double screenWidth) =>
      Padding(
        padding: EdgeInsets.only(bottom: screenWidth * 0.02),
        child: Row(
          children: [
            Text(
              '$label ₹${fee.toInt()}',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontSize: ResponsiveHelper.sp(14)),
            ),
            if (discount != null && discount > 0)
              Text(
                '  Discount:₹${discount.toInt()}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: ResponsiveHelper.sp(12),
                ),
              ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.edit, size: screenWidth * 0.045),
              onPressed: () => _showMembershipSheet(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
}
