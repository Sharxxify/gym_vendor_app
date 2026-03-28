class Business {
  final String id;
  final String? ownerId;
  final String name;
  final String? description;
  final String? profilePicture;
  final List<DisplayImage> displayImages;
  final List<String> images; // Convenience getter for backward compatibility
  final Address? address;
  final Location? location;
  final double rating;
  final int reviewCount;
  final BusinessHours? businessHours;
  final List<Service> services;
  final List<Facility> facilities;
  final List<String> amenities;
  final List<MembershipPlan> membershipPlans;
  final List<KycDocument> kycDocuments;
  final String status;
  final bool isVerified;
  final ElitePlan? elitePlan;
  final DateTime? createdAt;

  Business({
    required this.id,
    this.ownerId,
    required this.name,
    this.description,
    this.profilePicture,
    this.displayImages = const [],
    this.images = const [],
    this.address,
    this.location,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.businessHours,
    this.services = const [],
    this.facilities = const [],
    this.amenities = const [],
    this.membershipPlans = const [],
    this.kycDocuments = const [],
    this.status = 'pending',
    this.isVerified = false,
    this.elitePlan,
    this.createdAt,
  });

  /// Factory to parse the gym profile API response
  factory Business.fromApiResponse(Map<String, dynamic> json) {
    // Parse profile picture (first image from array)
    String? profilePic;
    if (json['profile_picture'] != null && json['profile_picture'] is List) {
      final profilePicList = json['profile_picture'] as List;
      if (profilePicList.isNotEmpty) {
        profilePic = profilePicList.first['s3_url'];
      }
    }

    // Parse display images
    List<DisplayImage> displayImgs = [];
    if (json['display_images'] != null && json['display_images'] is List) {
      displayImgs = (json['display_images'] as List)
          .map((e) => DisplayImage.fromJson(e))
          .toList();
    }

    // Parse rating
    double avgRating = 0.0;
    int totalReviews = 0;
    if (json['rating'] != null && json['rating'] is Map) {
      avgRating = (json['rating']['average'] ?? 0.0).toDouble();
      totalReviews = json['rating']['total_reviews'] ?? 0;
    }

    // Parse business hours
    BusinessHours? hours;
    if (json['business_hours'] != null && json['business_hours'] is Map) {
      hours = BusinessHours.fromApiResponse(json['business_hours']);
    }

    // Parse services
    List<Service> servicesList = [];
    if (json['services'] != null && json['services'] is List) {
      servicesList = (json['services'] as List)
          .map((e) => Service.fromApiResponse(e))
          .toList();
    }

    // Parse facilities
    List<Facility> facilitiesList = [];
    if (json['facilities'] != null && json['facilities'] is List) {
      facilitiesList = (json['facilities'] as List)
          .map((e) => Facility.fromApiResponse(e))
          .toList();
    }

    // Parse amenities
    List<String> amenitiesList = [];
    if (json['amenities'] != null && json['amenities'] is List) {
      amenitiesList = List<String>.from(json['amenities']);
    }

    // Parse membership plans
    List<MembershipPlan> membershipList = [];
    if (json['membership_fees'] != null && json['membership_fees'] is List) {
      membershipList = (json['membership_fees'] as List)
          .map((e) => MembershipPlan.fromJson(e))
          .toList();
    }

    // Parse KYC documents
    List<KycDocument> kycList = [];
    if (json['kyc_documents'] != null && json['kyc_documents'] is List) {
      kycList = (json['kyc_documents'] as List)
          .map((e) => KycDocument.fromJson(e))
          .toList();
    }

    // Parse elite plan
    ElitePlan? elite;
    if (json['elite_plan'] != null && json['elite_plan'] is Map) {
      elite = ElitePlan.fromJson(json['elite_plan']);
    }

    // Get gym name from business.about or use a default
    String gymName = 'My Business';
    if (json['business'] != null && json['business'] is Map) {
      // Name might be stored elsewhere, using about for now
      gymName = json['business']['name'] ?? gymName;
    }

    // Determine verification status
    final statusStr = json['status'] ?? 'pending';
    final isVerified = statusStr == 'verified' || statusStr == 'active';

    return Business(
      id: json['gym_id'] ?? json['_id'] ?? '',
      ownerId: json['owner_id'],
      name: gymName,
      description: json['business']?['about'],
      profilePicture: profilePic,
      displayImages: displayImgs,
      images: displayImgs.map((e) => e.url).toList(),
      address: json['address'] != null
          ? Address.fromApiResponse(json['address'])
          : null,
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
      rating: avgRating,
      reviewCount: totalReviews,
      businessHours: hours,
      services: servicesList,
      facilities: facilitiesList,
      amenities: amenitiesList,
      membershipPlans: membershipList,
      kycDocuments: kycList,
      status: statusStr,
      isVerified: isVerified,
      elitePlan: elite,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  factory Business.fromJson(Map<String, dynamic> json) {
    // Check if this is an API response or a local JSON format
    if (json.containsKey('gym_id') || json.containsKey('profile_picture')) {
      return Business.fromApiResponse(json);
    }

    // Legacy local JSON format
    return Business(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      images: List<String>.from(json['images'] ?? []),
      address:
          json['address'] != null ? Address.fromJson(json['address']) : null,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      businessHours: json['business_hours'] != null
          ? BusinessHours.fromJson(json['business_hours'])
          : null,
      services: (json['services'] as List?)
              ?.map((e) => Service.fromJson(e))
              .toList() ??
          [],
      facilities: (json['facilities'] as List?)
              ?.map((e) => Facility.fromJson(e))
              .toList() ??
          [],
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'profile_picture': profilePicture,
      'display_images': displayImages.map((e) => e.toJson()).toList(),
      'images': images,
      'address': address?.toJson(),
      'location': location?.toJson(),
      'rating': rating,
      'review_count': reviewCount,
      'business_hours': businessHours?.toJson(),
      'services': services.map((e) => e.toJson()).toList(),
      'facilities': facilities.map((e) => e.toJson()).toList(),
      'amenities': amenities,
      'membership_plans': membershipPlans.map((e) => e.toJson()).toList(),
      'status': status,
      'is_verified': isVerified,
      'elite_plan': elitePlan?.toJson(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Business copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? profilePicture,
    List<DisplayImage>? displayImages,
    List<String>? images,
    Address? address,
    Location? location,
    double? rating,
    int? reviewCount,
    BusinessHours? businessHours,
    List<Service>? services,
    List<Facility>? facilities,
    List<String>? amenities,
    List<MembershipPlan>? membershipPlans,
    List<KycDocument>? kycDocuments,
    String? status,
    bool? isVerified,
    ElitePlan? elitePlan,
    DateTime? createdAt,
  }) {
    return Business(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      profilePicture: profilePicture ?? this.profilePicture,
      displayImages: displayImages ?? this.displayImages,
      images: images ?? this.images,
      address: address ?? this.address,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      businessHours: businessHours ?? this.businessHours,
      services: services ?? this.services,
      facilities: facilities ?? this.facilities,
      amenities: amenities ?? this.amenities,
      membershipPlans: membershipPlans ?? this.membershipPlans,
      kycDocuments: kycDocuments ?? this.kycDocuments,
      status: status ?? this.status,
      isVerified: isVerified ?? this.isVerified,
      elitePlan: elitePlan ?? this.elitePlan,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isEliteMember => elitePlan?.isElite ?? false;
}

class DisplayImage {
  final String? id;
  final String url;
  final String? caption;
  final DateTime? uploadedAt;

  DisplayImage({
    this.id,
    required this.url,
    this.caption,
    this.uploadedAt,
  });

  factory DisplayImage.fromJson(Map<String, dynamic> json) {
    return DisplayImage(
      id: json['_id'],
      url: json['s3_url'] ?? '',
      caption: json['caption'],
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      's3_url': url,
      'caption': caption,
      'uploaded_at': uploadedAt?.toIso8601String(),
    };
  }
}

class Location {
  final double lat;
  final double lng;
  final String? formattedAddress;

  Location({
    required this.lat,
    required this.lng,
    this.formattedAddress,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      formattedAddress: json['formatted_address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'formatted_address': formattedAddress,
    };
  }
}

class Address {
  final String? id;
  final String buildingName;
  final String street;
  final String locality;
  final String city;
  final String state;
  final String pincode;
  final String country;

  Address({
    this.id,
    required this.buildingName,
    required this.street,
    required this.locality,
    required this.city,
    required this.state,
    required this.pincode,
    this.country = 'India',
  });

  /// Parse from API response format
  factory Address.fromApiResponse(Map<String, dynamic> json) {
    return Address(
      id: json['_id'],
      buildingName: json['building_name'] ?? '',
      street: json['street'] ?? '',
      locality: json['locality'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      country: json['country'] ?? 'India',
    );
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    // Check if this is API format or legacy format
    if (json.containsKey('building_name') && json.containsKey('locality')) {
      return Address.fromApiResponse(json);
    }

    // Legacy format
    return Address(
      id: json['id'],
      buildingName: json['building_name'] ?? '',
      street: json['road_area'] ?? json['street'] ?? '',
      locality: json['street_city'] ?? json['locality'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      country: json['country'] ?? 'India',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'building_name': buildingName,
      'street': street,
      'locality': locality,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
    };
  }

  String get displayAddress {
    final parts = [buildingName, street, locality, city, state, pincode]
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  String get shortAddress {
    return '$locality, $city';
  }

  // Backward compatibility getters
  String get roadArea => street;
  String get streetCity => '$locality, $city';
}

class TimeSlot {
  final String label;
  final String from;
  final String to;

  TimeSlot({
    this.label = 'Slot',
    required this.from,
    required this.to,
  });

  factory TimeSlot.fromApiResponse(Map<String, dynamic> json) {
    return TimeSlot(
      label: json['label'] ?? 'Slot',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
    );
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot.fromApiResponse(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'from': from,
      'to': to,
    };
  }

  Map<String, dynamic> toApiFormat() {
    return {
      'label': label,
      'from': from,
      'to': to,
    };
  }
}

class BusinessHours {
  final DayHours monday;
  final DayHours tuesday;
  final DayHours wednesday;
  final DayHours thursday;
  final DayHours friday;
  final DayHours saturday;
  final DayHours sunday;

  BusinessHours({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory BusinessHours.defaultHours() {
    return BusinessHours(
      monday: DayHours(isOpen: true, slots: [TimeSlot(label: 'Morning', from: '06:00 AM', to: '12:00 PM')]),
      tuesday: DayHours(isOpen: true, slots: [TimeSlot(label: 'Morning', from: '06:00 AM', to: '12:00 PM')]),
      wednesday: DayHours(isOpen: true, slots: [TimeSlot(label: 'Morning', from: '06:00 AM', to: '12:00 PM')]),
      thursday: DayHours(isOpen: true, slots: [TimeSlot(label: 'Morning', from: '06:00 AM', to: '12:00 PM')]),
      friday: DayHours(isOpen: true, slots: [TimeSlot(label: 'Morning', from: '06:00 AM', to: '12:00 PM')]),
      saturday: DayHours(isOpen: false),
      sunday: DayHours(isOpen: false),
    );
  }

  /// Parse from API response format (uses short day names: mon, tue, wed, etc.)
  factory BusinessHours.fromApiResponse(Map<String, dynamic> json) {
    return BusinessHours(
      monday: DayHours.fromApiResponse(json['mon']),
      tuesday: DayHours.fromApiResponse(json['tue']),
      wednesday: DayHours.fromApiResponse(json['wed']),
      thursday: DayHours.fromApiResponse(json['thu']),
      friday: DayHours.fromApiResponse(json['fri']),
      saturday: DayHours.fromApiResponse(json['sat']),
      sunday: DayHours.fromApiResponse(json['sun']),
    );
  }

  factory BusinessHours.fromJson(Map<String, dynamic> json) {
    // Check if this is API format (short names) or legacy format (full names)
    if (json.containsKey('mon') || json.containsKey('sat')) {
      return BusinessHours.fromApiResponse(json);
    }

    return BusinessHours(
      monday: DayHours.fromJson(json['monday'] ?? {}),
      tuesday: DayHours.fromJson(json['tuesday'] ?? {}),
      wednesday: DayHours.fromJson(json['wednesday'] ?? {}),
      thursday: DayHours.fromJson(json['thursday'] ?? {}),
      friday: DayHours.fromJson(json['friday'] ?? {}),
      saturday: DayHours.fromJson(json['saturday'] ?? {}),
      sunday: DayHours.fromJson(json['sunday'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monday': monday.toJson(),
      'tuesday': tuesday.toJson(),
      'wednesday': wednesday.toJson(),
      'thursday': thursday.toJson(),
      'friday': friday.toJson(),
      'saturday': saturday.toJson(),
      'sunday': sunday.toJson(),
    };
  }

  /// Convert to API format for sending to server
  Map<String, dynamic> toApiFormat() {
    return {
      'mon': monday.toApiFormat(),
      'tue': tuesday.toApiFormat(),
      'wed': wednesday.toApiFormat(),
      'thu': thursday.toApiFormat(),
      'fri': friday.toApiFormat(),
      'sat': saturday.toApiFormat(),
      'sun': sunday.toApiFormat(),
    };
  }

  BusinessHours copyWith({
    DayHours? monday,
    DayHours? tuesday,
    DayHours? wednesday,
    DayHours? thursday,
    DayHours? friday,
    DayHours? saturday,
    DayHours? sunday,
  }) {
    return BusinessHours(
      monday: monday ?? this.monday,
      tuesday: tuesday ?? this.tuesday,
      wednesday: wednesday ?? this.wednesday,
      thursday: thursday ?? this.thursday,
      friday: friday ?? this.friday,
      saturday: saturday ?? this.saturday,
      sunday: sunday ?? this.sunday,
    );
  }

  DayHours getDayHours(int dayIndex) {
    switch (dayIndex) {
      case 0:
        return monday;
      case 1:
        return tuesday;
      case 2:
        return wednesday;
      case 3:
        return thursday;
      case 4:
        return friday;
      case 5:
        return saturday;
      case 6:
        return sunday;
      default:
        return monday;
    }
  }

  operator [](String other) {}
}

class DayHours {
  final bool isOpen;
  final List<TimeSlot> slots;

  DayHours({
    required this.isOpen,
    this.slots = const [],
  });

  /// Parse from API response format
  factory DayHours.fromApiResponse(Map<String, dynamic>? json) {
    if (json == null) {
      return DayHours(isOpen: false);
    }
    List<TimeSlot> parsedSlots = [];
    if (json['slots'] != null && json['slots'] is List) {
      parsedSlots = (json['slots'] as List).map((e) => TimeSlot.fromApiResponse(e)).toList();
    } else if (json['from'] != null && json['to'] != null) {
      parsedSlots = [TimeSlot(label: 'Default', from: json['from'], to: json['to'])];
    }
    return DayHours(
      isOpen: json['open'] ?? false,
      slots: parsedSlots,
    );
  }

  factory DayHours.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('open') || json.containsKey('slots')) {
      return DayHours.fromApiResponse(json);
    }

    List<TimeSlot> parsedSlots = [];
    if (json['slots'] != null && json['slots'] is List) {
      parsedSlots = (json['slots'] as List).map((e) => TimeSlot.fromJson(e)).toList();
    } else if (json['open_time'] != null && json['close_time'] != null) {
      parsedSlots = [TimeSlot(label: 'Default', from: json['open_time'], to: json['close_time'])];
    }

    return DayHours(
      isOpen: json['is_open'] ?? false,
      slots: parsedSlots,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_open': isOpen,
      'slots': slots.map((e) => e.toJson()).toList(),
    };
  }

  /// Convert to API format for sending to server
  Map<String, dynamic> toApiFormat() {
    return {
      'open': isOpen,
      'slots': slots.map((e) => e.toApiFormat()).toList(),
    };
  }

  DayHours copyWith({
    bool? isOpen,
    List<TimeSlot>? slots,
  }) {
    return DayHours(
      isOpen: isOpen ?? this.isOpen,
      slots: slots ?? this.slots,
    );
  }

  String get displayTime {
    if (!isOpen) return 'Closed';
    if (slots.isEmpty) return 'Open';
    return slots.map((s) => '${s.from} - ${s.to}').join(', ');
  }
}

class Service {
  final String? id;
  final String name;
  final String? description;
  final double price;
  final String? priceUnit;
  final String? duration;
  final List<String> images;
  final List<TimeSlot> timeSlots;

  Service({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.priceUnit,
    this.duration,
    this.images = const [],
    this.timeSlots = const [],
  });

  /// Parse from API response format
  factory Service.fromApiResponse(Map<String, dynamic> json) {
    List<TimeSlot> slotsList = [];
    if (json['time_slots'] != null && json['time_slots'] is List) {
      slotsList = (json['time_slots'] as List).map((e) => TimeSlot.fromApiResponse(e)).toList();
    }
    return Service(
      id: json['_id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0.0).toDouble(),
      priceUnit: json['price_unit'],
      duration: json['duration'],
      images: List<String>.from(json['images'] ?? []),
      timeSlots: slotsList,
    );
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    // Check if this is API format or legacy format
    if (json.containsKey('price_unit') || json.containsKey('duration') || json.containsKey('time_slots')) {
      return Service.fromApiResponse(json);
    }

    List<TimeSlot> slotsList = [];
    if (json['time_slots'] != null && json['time_slots'] is List) {
      slotsList = (json['time_slots'] as List).map((e) => TimeSlot.fromJson(e)).toList();
    }
    return Service(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['fee'] ?? json['price'] ?? 0.0).toDouble(),
      priceUnit: json['fee_type'] ?? json['price_unit'],
      duration: json['duration'],
      images: List<String>.from(json['images'] ?? []),
      timeSlots: slotsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'price_unit': priceUnit,
      'duration': duration,
      'images': images,
      'time_slots': timeSlots.map((e) => e.toJson()).toList(),
    };
  }

  // Backward compatibility
  double get fee => price;
  String? get feeType => priceUnit;
}

class Facility {
  final String? id;
  final String name;
  final String? description;
  final bool isIncluded;
  final double price;
  final String? unit;

  Facility({
    this.id,
    required this.name,
    this.description,
    this.isIncluded = true,
    this.price = 0.0,
    this.unit,
  });

  /// Parse from API response format
  factory Facility.fromApiResponse(Map<String, dynamic> json) {
    return Facility(
      id: json['_id'],
      name: json['name'] ?? '',
      description: json['description'],
      isIncluded: json['included'] ?? true,
      price: (json['price'] ?? 0.0).toDouble(),
      unit: json['unit'],
    );
  }

  factory Facility.fromJson(Map<String, dynamic> json) {
    // Check if this is API format or legacy format
    if (json.containsKey('included') || json.containsKey('unit')) {
      return Facility.fromApiResponse(json);
    }

    return Facility(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      description: json['description'],
      isIncluded: json['is_available'] ?? json['included'] ?? true,
      price: (json['price'] ?? 0.0).toDouble(),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'included': isIncluded,
      'price': price,
      'unit': unit,
    };
  }

  // Backward compatibility
  bool get isAvailable => isIncluded;

  Facility copyWith({
    String? id,
    String? name,
    String? description,
    bool? isIncluded,
    double? price,
    String? unit,
  }) {
    return Facility(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isIncluded: isIncluded ?? this.isIncluded,
      price: price ?? this.price,
      unit: unit ?? this.unit,
    );
  }
}

class Equipment {
  final String? id;
  final String name;
  final List<String> images;

  Equipment({
    this.id,
    required this.name,
    this.images = const [],
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      images: List<String>.from(json['images'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'images': images,
    };
  }
}

class MembershipPlan {
  final String? id;
  final String type;
  final int durationMonths;
  final double price;
  final String currency;
  final List<String> features;

  MembershipPlan({
    this.id,
    required this.type,
    required this.durationMonths,
    required this.price,
    this.currency = 'INR',
    this.features = const [],
  });

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    List<String> featuresList = [];
    if (json['features'] != null && json['features'] is List) {
      featuresList = List<String>.from(json['features']);
    }

    return MembershipPlan(
      id: json['_id'],
      type: json['type'] ?? '',
      durationMonths: json['duration_months'] ?? 1,
      price: (json['price'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'INR',
      features: featuresList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'duration_months': durationMonths,
      'price': price,
      'currency': currency,
      'features': features,
    };
  }
}

class KycDocument {
  final String? id;
  final String type;
  final String url;
  final bool verified;

  KycDocument({
    this.id,
    required this.type,
    required this.url,
    this.verified = false,
  });

  factory KycDocument.fromJson(Map<String, dynamic> json) {
    return KycDocument(
      id: json['_id'],
      type: json['type'] ?? '',
      url: json['s3_url'] ?? '',
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      's3_url': url,
      'verified': verified,
    };
  }
}

class ElitePlan {
  final bool isElite;
  final String? planType;
  final DateTime? validTill;

  ElitePlan({
    required this.isElite,
    this.planType,
    this.validTill,
  });

  factory ElitePlan.fromJson(Map<String, dynamic> json) {
    return ElitePlan(
      isElite: json['is_elite'] ?? false,
      planType: json['plan_type'],
      validTill: json['valid_till'] != null
          ? DateTime.tryParse(json['valid_till'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_elite': isElite,
      'plan_type': planType,
      'valid_till': validTill?.toIso8601String(),
    };
  }

  bool get isValid {
    if (!isElite) return false;
    if (validTill == null) return false;
    return validTill!.isAfter(DateTime.now());
  }
}

// Legacy class for backward compatibility
class MembershipFee {
  final double? dailyFee;
  final double? dailyDiscount;
  final double? weeklyFee;
  final double? weeklyDiscount;
  final double? monthlyFee;
  final double? monthlyDiscount;
  final double? quarterlyFee;
  final double? quarterlyDiscount;
  final double? annualFee;
  final double? annualDiscount;

  MembershipFee({
    this.dailyFee,
    this.dailyDiscount,
    this.weeklyFee,
    this.weeklyDiscount,
    this.monthlyFee,
    this.monthlyDiscount,
    this.quarterlyFee,
    this.quarterlyDiscount,
    this.annualFee,
    this.annualDiscount,
  });

  factory MembershipFee.fromJson(Map<String, dynamic> json) {
    return MembershipFee(
      dailyFee: json['daily_fee']?.toDouble(),
      dailyDiscount: json['daily_discount']?.toDouble(),
      weeklyFee: json['weekly_fee']?.toDouble(),
      weeklyDiscount: json['weekly_discount']?.toDouble(),
      monthlyFee: json['monthly_fee']?.toDouble(),
      monthlyDiscount: json['monthly_discount']?.toDouble(),
      quarterlyFee: json['quarterly_fee']?.toDouble(),
      quarterlyDiscount: json['quarterly_discount']?.toDouble(),
      annualFee: json['annual_fee']?.toDouble(),
      annualDiscount: json['annual_discount']?.toDouble(),
    );
  }

  /// Create from list of MembershipPlan
  factory MembershipFee.fromPlans(List<MembershipPlan> plans) {
    double? monthly, quarterly, annual;

    for (final plan in plans) {
      switch (plan.durationMonths) {
        case 1:
          monthly = plan.price;
          break;
        case 3:
          quarterly = plan.price;
          break;
        case 12:
          annual = plan.price;
          break;
      }
    }

    return MembershipFee(
      monthlyFee: monthly,
      quarterlyFee: quarterly,
      annualFee: annual,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_fee': dailyFee,
      'daily_discount': dailyDiscount,
      'weekly_fee': weeklyFee,
      'weekly_discount': weeklyDiscount,
      'monthly_fee': monthlyFee,
      'monthly_discount': monthlyDiscount,
      'quarterly_fee': quarterlyFee,
      'quarterly_discount': quarterlyDiscount,
      'annual_fee': annualFee,
      'annual_discount': annualDiscount,
    };
  }

  double getDiscountedPrice(double? fee, double? discount) {
    if (fee == null) return 0;
    if (discount == null) return fee;
    return fee - discount;
  }
}
