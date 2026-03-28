import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/utils.dart';
import 'add_address_screen.dart';

class LocationPickerScreen extends StatefulWidget {
  final bool navigateToAddAddress;
  
  const LocationPickerScreen({
    super.key,
    this.navigateToAddAddress = true,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _selectedLocation = const LatLng(12.9716, 77.5946);
  String _selectedAddress = '';
  String _selectedPlaceName = 'Select Location';
  String _selectedCity = '';
  String _selectedState = '';
  String _selectedPincode = '';
  String _selectedStreet = '';
  String _selectedLocality = '';
  bool _isLoading = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionAndGetLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionAndGetLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showLocationServiceDisabledDialog();
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showPermissionDeniedForeverDialog();
        setState(() => _isLoading = false);
        return;
      }

      await _getCurrentLocation();
    } catch (e) {
      debugPrint('Error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Location Services Disabled', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Please enable GPS to set your gym location.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Permission Required', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Location permission is permanently denied. Please enable it in app settings.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final newLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = newLocation;
      });

      _mapController.move(newLocation, 16);
      await _getAddressFromCoordinates(newLocation);
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e'), backgroundColor: AppColors.error),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&addressdetails=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'BookMyFit/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};
        
        setState(() {
          _selectedPlaceName = data['name'] ?? 
                              address['road'] ?? 
                              address['neighbourhood'] ?? 
                              'Selected Location';
          _selectedStreet = address['road'] ?? address['neighbourhood'] ?? '';
          _selectedLocality = address['suburb'] ?? address['neighbourhood'] ?? '';
          _selectedCity = address['city'] ?? address['town'] ?? address['village'] ?? '';
          _selectedState = address['state'] ?? '';
          _selectedPincode = address['postcode'] ?? '';
          _selectedAddress = [
            _selectedLocality,
            _selectedCity,
            _selectedState,
          ].where((e) => e.isNotEmpty).join(', ');
        });
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
      setState(() {
        _selectedPlaceName = 'Selected Location';
        _selectedAddress = '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty || query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final url = 'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=5&addressdetails=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'BookMyFit/1.0'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((item) => {
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
            'name': item['display_name'],
            'address': item['address'],
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error searching: $e');
    }

    setState(() => _isSearching = false);
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final location = LatLng(result['lat'], result['lon']);
    
    setState(() {
      _selectedLocation = location;
      _searchResults = [];
      _searchController.clear();
    });

    FocusScope.of(context).unfocus();
    _mapController.move(location, 16);
    _getAddressFromCoordinates(location);
  }

  void _onMapTap(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
      _selectedPlaceName = 'Loading...';
    });
    _getAddressFromCoordinates(location);
  }

  void _confirmLocation() {
    if (_selectedPlaceName == 'Select Location' || _selectedPlaceName == 'Loading...') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first'), backgroundColor: Colors.orange),
      );
      return;
    }

    final locationData = {
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
      'address': _selectedAddress.isNotEmpty
          ? '$_selectedPlaceName, $_selectedAddress'
          : _selectedPlaceName,
      'placeName': _selectedPlaceName,
      'street': _selectedStreet,
      'locality': _selectedLocality,
      'city': _selectedCity,
      'state': _selectedState,
      'pincode': _selectedPincode,
    };

    if (widget.navigateToAddAddress) {
      // Navigate to Add Address screen with location data
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AddAddressScreen(locationData: locationData),
        ),
      );
    } else {
      // Just return the data
      Navigator.of(context).pop(locationData);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final screenHeight = ResponsiveHelper.screenHeight;
    final screenWidth = ResponsiveHelper.screenWidth;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Set Location',
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: ResponsiveHelper.sp(14),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search location',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                        fontSize: ResponsiveHelper.sp(14),
                      ),
                      prefixIcon: Icon(
                        Icons.search, 
                        color: AppColors.textSecondary,
                        size: screenWidth * 0.055,
                      ),
                      suffixIcon: _isSearching
                          ? Padding(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              child: SizedBox(
                                width: screenWidth * 0.05,
                                height: screenWidth * 0.05,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2, 
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: screenWidth * 0.05),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchResults = []);
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.015,
                      ),
                    ),
                    onChanged: _searchLocation,
                  ),
                ),

                // Search Results
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: screenHeight * 0.005),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    constraints: BoxConstraints(maxHeight: screenHeight * 0.25),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: Icon(
                            Icons.location_on_outlined, 
                            color: AppColors.textSecondary,
                            size: screenWidth * 0.055,
                          ),
                          title: Text(
                            result['name'] ?? 'Unknown',
                            style: AppTextStyles.labelMedium.copyWith(
                              fontSize: ResponsiveHelper.sp(13),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedLocation,
                        initialZoom: 15,
                        onTap: _onMapTap,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.bookmyfit.vendor',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation,
                              width: screenWidth * 0.12,
                              height: screenWidth * 0.12,
                              child: Icon(
                                Icons.location_on,
                                size: screenWidth * 0.12,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Instruction tooltip
                    Positioned(
                      top: screenHeight * 0.02,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.01,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(screenWidth * 0.05),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8),
                            ],
                          ),
                          child: Text(
                            'Place the pin to your location',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.black87,
                              fontSize: ResponsiveHelper.sp(12),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Current Location Button
                    Positioned(
                      bottom: screenHeight * 0.02,
                      right: screenWidth * 0.04,
                      child: GestureDetector(
                        onTap: _getCurrentLocation,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.012,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(screenWidth * 0.05),
                            border: Border.all(color: AppColors.primaryGreen),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: screenWidth * 0.025,
                                height: screenWidth * 0.025,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Text(
                                'Current Location',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primaryGreen,
                                  fontSize: ResponsiveHelper.sp(12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Loading overlay
                    if (_isLoading)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.primaryGreen),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Selected Location Info
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Icon(
                    Icons.location_on_outlined, 
                    color: AppColors.textPrimary,
                    size: screenWidth * 0.06,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPlaceName,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontSize: ResponsiveHelper.sp(14),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedAddress.isNotEmpty) ...[
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          _selectedAddress,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: ResponsiveHelper.sp(12),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Confirm Button
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.04, 
              0, 
              screenWidth * 0.04, 
              screenWidth * 0.04,
            ),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                text: 'Confirm Location',
                onPressed: _confirmLocation,
                isEnabled: _selectedPlaceName != 'Select Location' && _selectedPlaceName != 'Loading...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
