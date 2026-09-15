import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/producer_registration.dart';
import 'location_picker_screen.dart';

class ProducerRegistrationScreen extends StatefulWidget {
  const ProducerRegistrationScreen({super.key});

  @override
  State<ProducerRegistrationScreen> createState() =>
      _ProducerRegistrationScreenState();
}

class _ProducerRegistrationScreenState
    extends State<ProducerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------

  static const String _apiBaseUrl = 'http://167.86.66.79:4000';

  // ---------------------------------------------------------------------------
  // Basic information
  // ---------------------------------------------------------------------------

  final _businessNameController = TextEditingController();

  final _phoneController = TextEditingController();

  final _addressController = TextEditingController();

  final _regionController = TextEditingController();

  // ---------------------------------------------------------------------------
  // Dynamic lists
  // ---------------------------------------------------------------------------

  final List<TextEditingController> _rawMaterialControllers = [
    TextEditingController(),
  ];

  final List<TextEditingController> _sourcingChannelControllers = [
    TextEditingController(),
  ];

  final List<TextEditingController> _shortageMonthControllers = [
    TextEditingController(),
  ];

  final List<TextEditingController> _nutrientCropControllers = [
    TextEditingController(),
  ];

  // ---------------------------------------------------------------------------
  // Storage
  // ---------------------------------------------------------------------------

  final _storageCapacityController = TextEditingController();

  final _storageChallengesController = TextEditingController();

  // ---------------------------------------------------------------------------
  // Location
  // ---------------------------------------------------------------------------

  final _latitudeController = TextEditingController();

  final _longitudeController = TextEditingController();

  LatLng? _selectedLocation;

  // ---------------------------------------------------------------------------
  // Dropdown values
  // ---------------------------------------------------------------------------

  String _registrationType = '';

  String _ownershipStructure = '';

  String _organizationType = '';

  String _operationalScale = '';

  String _storageCapacityUnit = 'kg';

  String _accessibilityStatus = '';

  String _infrastructureStatus = '';

  String _sanitaryStatus = '';

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _submitting = false;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _regionController.dispose();

    for (final controller in _rawMaterialControllers) {
      controller.dispose();
    }

    for (final controller in _sourcingChannelControllers) {
      controller.dispose();
    }

    for (final controller in _shortageMonthControllers) {
      controller.dispose();
    }

    for (final controller in _nutrientCropControllers) {
      controller.dispose();
    }

    _storageCapacityController.dispose();
    _storageChallengesController.dispose();

    _latitudeController.dispose();
    _longitudeController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // DYNAMIC RAW MATERIALS
  // ===========================================================================

  void _addRawMaterial() {
    setState(() {
      _rawMaterialControllers.add(TextEditingController());
    });
  }

  void _removeRawMaterial(int index) {
    if (_rawMaterialControllers.length == 1) {
      _rawMaterialControllers[index].clear();
      return;
    }

    setState(() {
      _rawMaterialControllers[index].dispose();
      _rawMaterialControllers.removeAt(index);
    });
  }

  // ===========================================================================
  // DYNAMIC SOURCING CHANNELS
  // ===========================================================================

  void _addSourcingChannel() {
    setState(() {
      _sourcingChannelControllers.add(TextEditingController());
    });
  }

  void _removeSourcingChannel(int index) {
    if (_sourcingChannelControllers.length == 1) {
      _sourcingChannelControllers[index].clear();
      return;
    }

    setState(() {
      _sourcingChannelControllers[index].dispose();
      _sourcingChannelControllers.removeAt(index);
    });
  }

  // ===========================================================================
  // DYNAMIC SHORTAGE MONTHS
  // ===========================================================================

  void _addShortageMonth() {
    setState(() {
      _shortageMonthControllers.add(TextEditingController());
    });
  }

  void _removeShortageMonth(int index) {
    if (_shortageMonthControllers.length == 1) {
      _shortageMonthControllers[index].clear();
      return;
    }

    setState(() {
      _shortageMonthControllers[index].dispose();
      _shortageMonthControllers.removeAt(index);
    });
  }

  // ===========================================================================
  // DYNAMIC NUTRIENT-DENSE CROPS
  // ===========================================================================

  void _addNutrientCrop() {
    setState(() {
      _nutrientCropControllers.add(TextEditingController());
    });
  }

  void _removeNutrientCrop(int index) {
    if (_nutrientCropControllers.length == 1) {
      _nutrientCropControllers[index].clear();
      return;
    }

    setState(() {
      _nutrientCropControllers[index].dispose();
      _nutrientCropControllers.removeAt(index);
    });
  }

  // ===========================================================================
  // LOCATION PICKER
  // ===========================================================================

  Future<void> _selectLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LocationPickerScreen(initialLocation: _selectedLocation),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedLocation = result;

      _latitudeController.text = result.latitude.toStringAsFixed(6);

      _longitudeController.text = result.longitude.toStringAsFixed(6);
    });
  }

  // ===========================================================================
  // CURRENT GPS LOCATION
  // ===========================================================================

  Future<void> _useCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services.')),
        );

        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission was not granted.')),
        );

        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Getting your location...'),
                  ],
                ),
              ),
            ),
          );
        },
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      final location = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = location;

        _latitudeController.text = position.latitude.toStringAsFixed(6);

        _longitudeController.text = position.longitude.toStringAsFixed(6);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location selected.')),
      );
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
    }
  }

  // ===========================================================================
  // MANUAL COORDINATES
  // ===========================================================================

  void _setManualCoordinates() {
    final latitude = double.tryParse(_latitudeController.text.trim());

    final longitude = double.tryParse(_longitudeController.text.trim());

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid latitude and longitude.')),
      );

      return;
    }

    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid coordinate range.')),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _selectedLocation = LatLng(latitude, longitude);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coordinates applied.')));
  }

  // ===========================================================================
  // COLLECT LIST VALUES
  // ===========================================================================

  List<String> _getValues(List<TextEditingController> controllers) {
    return controllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  // ===========================================================================
  // SUBMIT
  // ===========================================================================

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final latitude = double.tryParse(_latitudeController.text.trim());

    final longitude = double.tryParse(_longitudeController.text.trim());

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide the producer location.')),
      );

      return;
    }

    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid latitude or longitude.')),
      );

      return;
    }

    final rawMaterials = _getValues(_rawMaterialControllers);

    final sourcingChannels = _getValues(_sourcingChannelControllers);

    final shortageMonths = _getValues(_shortageMonthControllers);

    final nutrientDenseCrops = _getValues(_nutrientCropControllers);

    if (rawMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one primary raw material.')),
      );

      return;
    }

    if (sourcingChannels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one primary sourcing channel.'),
        ),
      );

      return;
    }

    if (nutrientDenseCrops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one nutrient-dense crop or product.'),
        ),
      );

      return;
    }

    final registration = ProducerRegistration(
      businessName: _businessNameController.text.trim(),

      registrationType: _registrationType,

      ownershipStructure: _ownershipStructure,

      organizationType: _organizationType,

      operationalScale: _operationalScale,

      phone: _phoneController.text.trim(),

      physicalAddress: _addressController.text.trim(),

      region: _regionController.text.trim(),

      primaryRawMaterials: rawMaterials.join(', '),

      primarySourcingChannels: sourcingChannels.join(', '),

      shortageMonths: shortageMonths.join(', '),

      storageCapacity: _storageCapacityController.text.trim(),

      storageCapacityUnit: _storageCapacityUnit,

      mainStorageChallenges: _storageChallengesController.text.trim(),

      nutrientDenseCrops: nutrientDenseCrops.join(', '),

      accessibilityStatus: _accessibilityStatus,

      infrastructureStatus: _infrastructureStatus,

      sanitaryStatus: _sanitaryStatus,

      latitude: latitude,

      longitude: longitude,
    );

    setState(() {
      _submitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/producers'),

        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },

        body: jsonEncode(registration.toJson()),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producer registered successfully.')),
        );

        Navigator.pop(context, true);

        return;
      }

      String message = 'Registration failed.';

      try {
        final body = jsonDecode(response.body);

        if (body is Map && body['message'] != null) {
          message = body['message'].toString();
        } else if (body is Map && body['error'] != null) {
          message = body['error'].toString();
        }
      } catch (_) {
        // Response wasn't JSON.
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message (${response.statusCode})')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to connect to server: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Producer')),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),

            child: Form(
              key: _formKey,

              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // ==========================================================
                    // BUSINESS INFORMATION
                    // ==========================================================
                    _sectionTitle('Business Information', Icons.business),

                    const SizedBox(height: 16),

                    _textField(
                      controller: _businessNameController,
                      label: 'Business name',
                      icon: Icons.business,
                      required: true,
                    ),

                    const SizedBox(height: 16),

                    _responsiveFields(context, [
                      _dropdown(
                        label: 'Registration type',
                        value: _registrationType,
                        items: const [
                          'Registered company',
                          'Sole proprietor',
                          'Partnership',
                          'Cooperative',
                          'Other',
                        ],
                        onChanged: (value) {
                          setState(() {
                            _registrationType = value ?? '';
                          });
                        },
                      ),

                      _dropdown(
                        label: 'Ownership structure',
                        value: _ownershipStructure,
                        items: const [
                          'Private',
                          'Public',
                          'Cooperative',
                          'Family owned',
                          'Other',
                        ],
                        onChanged: (value) {
                          setState(() {
                            _ownershipStructure = value ?? '';
                          });
                        },
                      ),
                    ]),

                    const SizedBox(height: 16),

                    _responsiveFields(context, [
                      _dropdown(
                        label: 'Organization type',
                        value: _organizationType,
                        items: const [
                          'Farm',
                          'Processor',
                          'Factory',
                          'Food producer',
                          'Distributor',
                          'Other',
                        ],
                        onChanged: (value) {
                          setState(() {
                            _organizationType = value ?? '';
                          });
                        },
                      ),

                      _dropdown(
                        label: 'Operational scale',
                        value: _operationalScale,
                        items: const ['Small', 'Medium', 'Large'],
                        onChanged: (value) {
                          setState(() {
                            _operationalScale = value ?? '';
                          });
                        },
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // ==========================================================
                    // CONTACT
                    // ==========================================================
                    _sectionTitle('Contact Information', Icons.contact_phone),

                    const SizedBox(height: 16),

                    _responsiveFields(context, [
                      _textField(
                        controller: _phoneController,
                        label: 'Phone number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),

                      _textField(
                        controller: _regionController,
                        label: 'Region',
                        icon: Icons.map,
                      ),
                    ]),

                    const SizedBox(height: 16),

                    _textField(
                      controller: _addressController,
                      label: 'Physical address',
                      icon: Icons.location_on,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 32),

                    // ==========================================================
                    // LOCATION
                    // ==========================================================
                    _sectionTitle('Producer Location', Icons.location_pin),

                    const SizedBox(height: 8),

                    Text(
                      'Choose the exact location of the producer using GPS, '
                      'the map, or enter coordinates manually.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 16),

                    _locationCard(),

                    const SizedBox(height: 32),

                    // ==========================================================
                    // RAW MATERIALS
                    // ==========================================================
                    _sectionTitle('Primary Raw Materials', Icons.inventory_2),

                    const SizedBox(height: 8),

                    Text(
                      'Add all major raw materials used by this producer.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 16),

                    _dynamicListField(
                      title: 'Raw material',
                      hint: 'Example: Soybeans',
                      icon: Icons.inventory_2,
                      controllers: _rawMaterialControllers,
                      onAdd: _addRawMaterial,
                      onRemove: _removeRawMaterial,
                    ),

                    const SizedBox(height: 32),

                    // ==========================================================
                    // SOURCING CHANNELS
                    // ==========================================================
                    _sectionTitle(
                      'Primary Sourcing Channels',
                      Icons.local_shipping,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Add all channels through which raw materials are sourced.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 16),

                    _dynamicListField(
                      title: 'Sourcing channel',
                      hint: 'Example: Commercial Aggregators / Middlemen',
                      icon: Icons.local_shipping,
                      controllers: _sourcingChannelControllers,
                      onAdd: _addSourcingChannel,
                      onRemove: _removeSourcingChannel,
                    ),

                    const SizedBox(height: 32),

                    // ==========================================================
                    // SHORTAGE MONTHS
                    // ==========================================================
                    _sectionTitle('Shortage Months', Icons.calendar_month),

                    const SizedBox(height: 8),

                    Text(
                      'Add months when raw materials are commonly in shortage.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 16),

                    _dynamicListField(
                      title: 'Shortage month',
                      hint: 'Example: January',
                      icon: Icons.calendar_month,
                      controllers: _shortageMonthControllers,
                      onAdd: _addShortageMonth,
                      onRemove: _removeShortageMonth,
                    ),

                    const SizedBox(height: 32),

                    // ==========================================================
                    // NUTRIENT DENSE CROPS
                    // ==========================================================
                    _sectionTitle('Nutrient-Dense Crops / Products', Icons.eco),

                    const SizedBox(height: 8),

                    Text(
                      'Add all relevant nutrient-dense crops or products.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 16),

                    _dynamicListField(
                      title: 'Nutrient-dense crop/product',
                      hint: 'Example: Soybeans',
                      icon: Icons.eco,
                      controllers: _nutrientCropControllers,
                      onAdd: _addNutrientCrop,
                      onRemove: _removeNutrientCrop,
                    ),

                    const SizedBox(height: 32),

                    // ==========================================================
                    // STORAGE
                    // ==========================================================
                    _sectionTitle('Storage', Icons.warehouse),

                    const SizedBox(height: 16),

                    _responsiveFields(context, [
                      _textField(
                        controller: _storageCapacityController,
                        label: 'Storage capacity',
                        icon: Icons.storage,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      _dropdown(
                        label: 'Storage unit',
                        value: _storageCapacityUnit,
                        items: const [
                          'kg',
                          'tonnes',
                          'litres',
                          'units',
                          'bags',
                        ],
                        onChanged: (value) {
                          setState(() {
                            _storageCapacityUnit = value ?? 'kg';
                          });
                        },
                      ),
                    ]),

                    const SizedBox(height: 16),

                    _textField(
                      controller: _storageChallengesController,
                      label: 'Main storage challenges',
                      icon: Icons.warning_amber,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // ==========================================================
                    // INFRASTRUCTURE
                    // ==========================================================
                    _sectionTitle(
                      'Infrastructure & Standards',
                      Icons.verified_user,
                    ),

                    const SizedBox(height: 16),

                    _responsiveFields(context, [
                      _dropdown(
                        label: 'Accessibility status',
                        value: _accessibilityStatus,
                        items: const ['Good', 'Fair', 'Poor'],
                        onChanged: (value) {
                          setState(() {
                            _accessibilityStatus = value ?? '';
                          });
                        },
                      ),

                      _dropdown(
                        label: 'Infrastructure status',
                        value: _infrastructureStatus,
                        items: const ['Good', 'Fair', 'Poor'],
                        onChanged: (value) {
                          setState(() {
                            _infrastructureStatus = value ?? '';
                          });
                        },
                      ),
                    ]),

                    const SizedBox(height: 16),

                    _dropdown(
                      label: 'Sanitary status',
                      value: _sanitaryStatus,
                      items: const ['Good', 'Fair', 'Poor'],
                      onChanged: (value) {
                        setState(() {
                          _sanitaryStatus = value ?? '';
                        });
                      },
                    ),

                    const SizedBox(height: 40),

                    // ==========================================================
                    // SUBMIT
                    // ==========================================================
                    SizedBox(
                      width: double.infinity,
                      height: 54,

                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,

                        icon: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle),

                        label: Text(
                          _submitting ? 'Registering...' : 'Register Producer',
                        ),

                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LOCATION CARD
  // ===========================================================================

  Widget _locationCard() {
    final hasLocation = _selectedLocation != null;

    return Card(
      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),

        side: BorderSide(color: Colors.grey.shade300),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    color: hasLocation
                        ? Colors.green.shade50
                        : Colors.grey.shade100,

                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    hasLocation ? Icons.location_on : Icons.location_off,

                    color: hasLocation
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        hasLocation
                            ? 'Location selected'
                            : 'Location not selected',

                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        hasLocation
                            ? '${_latitudeController.text}, '
                                  '${_longitudeController.text}'
                            : 'Use GPS or select a point on the map',

                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _useCurrentLocation,

                    icon: const Icon(Icons.my_location),

                    label: const Text('Use GPS'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectLocation,

                    icon: const Icon(Icons.map),

                    label: const Text('Select Map'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _responsiveFields(context, [
              _textField(
                controller: _latitudeController,
                label: 'Latitude',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),

              _textField(
                controller: _longitudeController,
                label: 'Longitude',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
              ),
            ]),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,

              child: TextButton.icon(
                onPressed: _setManualCoordinates,

                icon: const Icon(Icons.edit_location_alt),

                label: const Text('Apply coordinates'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DYNAMIC LIST FIELD
  // ===========================================================================

  Widget _dynamicListField({
    required String title,
    required String hint,
    required IconData icon,
    required List<TextEditingController> controllers,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        ...List.generate(controllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Expanded(
                  child: TextFormField(
                    controller: controllers[index],

                    decoration: InputDecoration(
                      labelText: '$title ${index + 1}',

                      hintText: hint,

                      prefixIcon: Icon(icon),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),

                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 6),

                IconButton(
                  tooltip: 'Remove',

                  onPressed: () {
                    onRemove(index);
                  },

                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          );
        }),

        OutlinedButton.icon(
          onPressed: onAdd,

          icon: const Icon(Icons.add),

          label: Text('Add another $title'),
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION TITLE
  // ===========================================================================

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.green.shade700),

        const SizedBox(width: 8),

        Text(
          title,

          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ===========================================================================
  // TEXT FIELD
  // ===========================================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,

      maxLines: maxLines,

      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: required ? '$label *' : label,

        hintText: hint,

        prefixIcon: icon == null ? null : Icon(icon),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),

          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),

      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }

              return null;
            }
          : null,
    );
  }

  // ===========================================================================
  // DROPDOWN
  // ===========================================================================

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,

      decoration: InputDecoration(
        labelText: label,

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),

          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),

      items: items.map((item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),

      onChanged: onChanged,
    );
  }

  // ===========================================================================
  // RESPONSIVE TWO-COLUMN LAYOUT
  // ===========================================================================

  Widget _responsiveFields(BuildContext context, List<Widget> children) {
    final width = MediaQuery.sizeOf(context).width;

    if (width < 700) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],

            if (i < children.length - 1) const SizedBox(height: 16),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),

          if (i < children.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }
}
