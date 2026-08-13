class Company {
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

  const Company({
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

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      description: '${json['description'] ?? ''}',
      category: '${json['category'] ?? 'Food & Nutrition'}',
      address: '${json['address'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      website: '${json['website'] ?? ''}',
      logoUrl: '${json['logoUrl'] ?? ''}',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      verified: json['verified'] == true,
      openNow: json['openNow'] != false,
      highlights: List<String>.from(json['highlights'] ?? const []),
    );
  }
}
