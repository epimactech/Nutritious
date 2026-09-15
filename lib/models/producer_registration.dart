class ProducerRegistration {
  String businessName;
  String registrationType;
  String ownershipStructure;
  String organizationType;
  String operationalScale;
  String phone;
  String physicalAddress;
  String region;

  String primaryRawMaterials;
  String primarySourcingChannels;
  String shortageMonths;

  String storageCapacity;
  String storageCapacityUnit;
  String mainStorageChallenges;

  String nutrientDenseCrops;

  String accessibilityStatus;
  String infrastructureStatus;
  String sanitaryStatus;

  double? latitude;
  double? longitude;

  ProducerRegistration({
    this.businessName = '',
    this.registrationType = '',
    this.ownershipStructure = '',
    this.organizationType = '',
    this.operationalScale = '',
    this.phone = '',
    this.physicalAddress = '',
    this.region = '',
    this.primaryRawMaterials = '',
    this.primarySourcingChannels = '',
    this.shortageMonths = '',
    this.storageCapacity = '',
    this.storageCapacityUnit = '',
    this.mainStorageChallenges = '',
    this.nutrientDenseCrops = '',
    this.accessibilityStatus = '',
    this.infrastructureStatus = '',
    this.sanitaryStatus = '',
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'business_name': businessName,
      'registration_type': registrationType,
      'ownership_structure': ownershipStructure,
      'organization_type': organizationType,
      'operational_scale': operationalScale,
      'phone': phone,
      'physical_address': physicalAddress,
      'region': region,

      'primary_raw_materials': primaryRawMaterials,
      'primary_sourcing_channels': primarySourcingChannels,
      'shortage_months': shortageMonths,

      'storage_capacity': storageCapacity,
      'storage_capacity_unit': storageCapacityUnit,
      'main_storage_challenges': mainStorageChallenges,

      'nutrient_dense_crops': nutrientDenseCrops,

      'accessibility_status': accessibilityStatus,
      'infrastructure_status': infrastructureStatus,
      'sanitary_status': sanitaryStatus,

      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
