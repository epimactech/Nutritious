class Producer {
  final String id;
  final String name;
  final String description;
  final String category;
  final String address;
  final String phone;
  final String website;
  final String logoUrl;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviews;
  final bool verified;
  final bool openNow;
  final List<String> highlights;

  const Producer({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    required this.phone,
    required this.website,
    required this.logoUrl,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.reviews,
    required this.verified,
    required this.openNow,
    required this.highlights,
  });

  factory Producer.fromJson(Map<String, dynamic> json) {
    final rawMaterials = _stringList(json['primary_raw_materials']);
    final nutrientCrops = _stringList(json['nutrient_dense_crops']);
    final sourcingChannels = _stringList(json['primary_sourcing_channels']);
    final shortageMonths = _stringList(json['shortage_months']);
    final storageChallenges = _stringList(json['main_storage_challenges']);

    final region = json['region'];
    final regionName = region is Map ? region['name']?.toString() ?? '' : '';

    final businessName = json['business_name']?.toString().trim() ?? '';

    final address = json['physical_address']?.toString().trim() ?? '';

    final organizationType = json['organization_type']?.toString().trim() ?? '';

    final registrationType = json['registration_type']?.toString().trim() ?? '';

    final ownership = json['ownership_structure']?.toString().trim() ?? '';

    final operationalScale = json['operational_scale']?.toString().trim() ?? '';

    final operationalStatus =
        json['operational_status']?.toString().trim() ?? '';

    final verificationStatus =
        json['verification_status']?.toString().toLowerCase() ?? '';

    final status = json['status']?.toString().toLowerCase() ?? '';

    return Producer(
      id: json['id']?.toString() ?? '',

      // API: business_name
      name: businessName.isNotEmpty ? businessName : 'Unnamed company',

      // Build a useful description from the API data.
      description: _buildDescription(
        json: json,
        rawMaterials: rawMaterials,
        nutrientCrops: nutrientCrops,
        sourcingChannels: sourcingChannels,
      ),

      // API can have organization_type null, so use
      // registration type / ownership as fallback.
      category: organizationType.isNotEmpty
          ? organizationType
          : registrationType.isNotEmpty
          ? registrationType
          : ownership.isNotEmpty
          ? ownership
          : 'Food & Nutrition',

      // API: physical_address
      address: address,

      // API: phone
      phone: json['phone']?.toString() ?? '',

      // No website field in current API.
      website: '',

      // No logo field in current API.
      logoUrl: '',

      // API: latitude / longitude
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),

      // API currently doesn't provide ratings.
      rating: _toDouble(json['rating']),

      // API currently doesn't provide review count.
      reviews: _toInt(json['reviews']),

      // Current API uses verification_status.
      verified:
          verificationStatus == 'verified' ||
          verificationStatus == 'approved' ||
          verificationStatus == 'validated',

      // Current API uses operational_status/status.
      openNow:
          status == 'active' ||
          operationalStatus.toLowerCase().startsWith('active'),

      highlights: [
        if (ownership.isNotEmpty) ownership,

        if (operationalScale.isNotEmpty) operationalScale,

        if (operationalStatus.isNotEmpty) operationalStatus,

        if (regionName.isNotEmpty) 'Region: $regionName',

        if (json['contact_person'] != null &&
            json['contact_person'].toString().trim().isNotEmpty)
          'Contact: ${json['contact_person']}',

        if (rawMaterials.isNotEmpty)
          'Raw materials: ${rawMaterials.join(', ')}',

        if (nutrientCrops.isNotEmpty)
          'Nutrient-dense: ${nutrientCrops.join(', ')}',

        if (sourcingChannels.isNotEmpty)
          'Sourcing: ${sourcingChannels.join(', ')}',

        if (shortageMonths.isNotEmpty)
          'Shortage months: ${shortageMonths.join(', ')}',

        if (json['post_harvest_loss_percent'] != null)
          'Post-harvest loss: '
              '${json['post_harvest_loss_percent']}%',

        if (json['storage_capacity'] != null)
          'Storage: '
              '${json['storage_capacity']} '
              '${json['storage_capacity_unit'] ?? ''}',

        if (storageChallenges.isNotEmpty)
          'Storage challenges: '
              '${storageChallenges.join(', ')}',

        if (json['accessibility_status'] != null)
          'Accessibility: ${json['accessibility_status']}',

        if (json['infrastructure_status'] != null)
          'Infrastructure: ${json['infrastructure_status']}',

        if (json['sanitary_status'] != null)
          'Sanitary status: ${json['sanitary_status']}',

        if (json['harvest_cycles_per_year'] != null)
          'Harvest cycles: '
              '${json['harvest_cycles_per_year']}',

        if (json['average_yield'] != null)
          'Average yield: '
              '${json['average_yield']} '
              '${json['yield_unit'] ?? ''}',
      ],
    );
  }

  static String _buildDescription({
    required Map<String, dynamic> json,
    required List<String> rawMaterials,
    required List<String> nutrientCrops,
    required List<String> sourcingChannels,
  }) {
    final parts = <String>[];

    if (rawMaterials.isNotEmpty) {
      parts.add(
        'Primary raw materials include '
        '${rawMaterials.join(', ')}.',
      );
    }

    if (nutrientCrops.isNotEmpty) {
      parts.add(
        'Nutrient-dense products/crops include '
        '${nutrientCrops.join(', ')}.',
      );
    }

    if (sourcingChannels.isNotEmpty) {
      parts.add(
        'The company sources through '
        '${sourcingChannels.join(', ')}.',
      );
    }

    if (json['production_capacity'] != null) {
      parts.add(
        'Production capacity: '
        '${json['production_capacity']}.',
      );
    }

    if (json['daily_output'] != null) {
      parts.add('Daily output: ${json['daily_output']}.');
    }

    if (parts.isEmpty) {
      return 'Food and nutrition producer.';
    }

    return parts.join(' ');
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .where((item) => item != null)
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }
}

// class Company {
//   final String id;
//   final String name;
//   final String description;
//   final String category;
//   final String address;
//   final String phone;
//   final String website;
//   final String logoUrl;
//   final double latitude;
//   final double longitude;
//   final double rating;
//   final int reviews;
//   final bool verified;
//   final bool openNow;
//   final List<String> highlights;

//   const Company({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.category,
//     required this.address,
//     required this.phone,
//     required this.website,
//     required this.logoUrl,
//     required this.latitude,
//     required this.longitude,
//     required this.rating,
//     required this.reviews,
//     required this.verified,
//     required this.openNow,
//     required this.highlights,
//   });

//   factory Company.fromJson(Map<String, dynamic> json) {
//     return Company(
//       id: '${json['id'] ?? ''}',
//       name: '${json['name'] ?? ''}',
//       description: '${json['description'] ?? ''}',
//       category: '${json['category'] ?? 'Food & Nutrition'}',
//       address: '${json['address'] ?? ''}',
//       phone: '${json['phone'] ?? ''}',
//       website: '${json['website'] ?? ''}',
//       logoUrl: '${json['logoUrl'] ?? ''}',
//       latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
//       longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
//       rating: (json['rating'] as num?)?.toDouble() ?? 0,
//       reviews: (json['reviews'] as num?)?.toInt() ?? 0,
//       verified: json['verified'] == true,
//       openNow: json['openNow'] != false,
//       highlights: List<String>.from(json['highlights'] ?? const []),
//     );
//   }
// }
