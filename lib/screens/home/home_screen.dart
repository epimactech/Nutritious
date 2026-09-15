import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/company_repository.dart';
import '../../models/producer.dart';
import '../../services/location_service.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/producer_card.dart';
import '../../widgets/producer_details.dart';
import '../../widgets/producer_details_modal.dart';
import '../../widgets/map_view.dart';
import '../../widgets/mobile_bottom_navigation.dart';
import '../account/account_screen.dart';
import '../producers/producers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CompanyRepository repository = ApiCompanyRepository(
    baseUrl: 'https://footballfraternity.co.tz',
  );
  final LocationService locationService = LocationService();
  List<Producer> producers = [];
  Producer? selected;
  LatLng? userLocation;
  int navIndex = 0;
  bool loading = true;
  String query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await repository.getCompanies();
      if (mounted)
        setState(() {
          producers = data;
          loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _locate() async {
    final position = await locationService.currentPosition();
    if (position != null && mounted)
      setState(
        () => userLocation = LatLng(position.latitude, position.longitude),
      );
  }

  void _select(Producer producer) {
    setState(() => selected = producer);
    if (Responsive.isMobile(context))
      showProducerDetailsModal(context, producer);
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (Responsive.isMobile(context)) return _mobile();
    return _desktop();
  }

  Widget _mobile() {
    final body = switch (navIndex) {
      0 => _mobileMap(),
      1 => ProducersScreen(producers: producers, onSelect: _select),
      _ => const AccountScreen(),
    };
    return Scaffold(
      body: body,
      bottomNavigationBar: MobileBottomNavigation(
        index: navIndex,
        onChanged: (i) => setState(() => navIndex = i),
      ),
    );
  }

  Widget _mobileMap() => Stack(
    children: [
      Positioned.fill(
        child: MapView(
          producers: producers,
          selectedProducer: selected,
          onProducerSelected: _select,
        ),
      ),
      Positioned(
        top: 18,
        left: 16,
        right: 16,
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.white,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(16),
                  child: TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search nutritious companies...',
                      filled: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _roundButton(Icons.my_location, _locate),
            ],
          ),
        ),
      ),
      if (query.isNotEmpty)
        Positioned(
          top: 90,
          left: 16,
          right: 16,
          child: Card(
            child: Column(
              children: producers
                  .where(
                    (p) => p.name.toLowerCase().contains(query.toLowerCase()),
                  )
                  .take(5)
                  .map(
                    (p) => ProducerCard(
                      producer: p,
                      onTap: () {
                        setState(() => query = '');
                        _select(p);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      Positioned(bottom: 18, left: 16, right: 16, child: _mapHint()),
    ],
  );

  Widget _desktop() => Scaffold(
    body: Row(
      children: [
        AppSidebar(
          selectedIndex: navIndex,
          onSelected: (i) => setState(() {
            navIndex = i;
            if (i != 0) selected = null;
          }),
        ),
        Expanded(
          child: navIndex == 0
              ? _desktopMap()
              : navIndex == 1
              ? ProducersScreen(producers: producers, onSelect: _select)
              : const AccountScreen(),
        ),
      ],
    ),
  );

  Widget _desktopMap() => Row(
    children: [
      Expanded(
        flex: 7,
        child: Stack(
          children: [
            Positioned.fill(
              child: MapView(
                producers: producers,

                selectedProducer: selected,
                onProducerSelected: (Producer value) {
                  print('Selected producers: ${value.name}');
                  setState(() {
                    selected = value;
                  });
                },
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              width: 420,
              child: Material(
                color: Colors.white,
                elevation: 3,
                borderRadius: BorderRadius.circular(16),
                child: TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search producers, categories or areas...',
                    filled: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: _roundButton(Icons.my_location, _locate),
            ),
            if (query.isNotEmpty)
              Positioned(
                top: 78,
                left: 20,
                width: 420,
                child: Card(
                  child: Column(
                    children: producers
                        .where(
                          (p) =>
                              p.name.toLowerCase().contains(
                                query.toLowerCase(),
                              ) ||
                              p.category.toLowerCase().contains(
                                query.toLowerCase(),
                              ),
                        )
                        .take(5)
                        .map(
                          (p) => ProducerCard(
                            producer: p,
                            onTap: () => setState(() {
                              query = '';
                              selected = p;
                            }),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
      Container(
        width: 390,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(left: BorderSide(color: Color(0xFFE5E9E7))),
        ),
        child: selected == null
            ? _desktopEmptyDetails()
            : ProducerDetails(producer: selected!),
      ),
    ],
  );

  Widget _desktopEmptyDetails() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: .12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.touch_app_outlined,
              size: 34,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Select a producer to view details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap any map marker to see producer information, nutrition highlights and contact options.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, height: 1.45),
          ),
        ],
      ),
    ),
  );

  Widget _mapHint() => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Tap a marker to explore a producer',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.touch_app_outlined, color: AppTheme.primary),
        ],
      ),
    ),
  );

  Widget _roundButton(IconData icon, VoidCallback onTap) => Material(
    color: Colors.white,
    elevation: 4,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Icon(icon, color: AppTheme.primary),
      ),
    ),
  );
}
