import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:nutrious/models/producer.dart';
import 'package:nutrious/services/dashboard_api_service.dart';

class ProducerDashboardScreen extends StatefulWidget {
  final DashboardApiService apiService;
  final ValueChanged<Producer>? onSelectProducer;

  const ProducerDashboardScreen({
    super.key,
    required this.apiService,
    this.onSelectProducer,
  });

  @override
  State<ProducerDashboardScreen> createState() =>
      _ProducerDashboardScreenState();
}

class _ProducerDashboardScreenState extends State<ProducerDashboardScreen> {
  late Future<DashboardData> _future;
  String _period = '12 months';
  String _search = '';

  static const _navy = Color(0xFF10243A);
  static const _green = Color(0xFF17865B);
  static const _page = Color(0xFFF4F7FA);

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.fetchDashboard();
  }

  Future<void> _refresh() async {
    final next = widget.apiService.fetchDashboard();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: FutureBuilder<DashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError && !snapshot.hasData) {
              return _ErrorState(
                error: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return _ErrorState(
                error: 'No dashboard data returned .',
                onRetry: _refresh,
              );
            }
            final matches = data.producers
                .where((p) {
                  final q = _search.toLowerCase().trim();
                  return q.isEmpty ||
                      p.name.toLowerCase().contains(q) ||
                      p.category.toLowerCase().contains(q);
                })
                .take(5)
                .toList();

            return RefreshIndicator(
              onRefresh: _refresh,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 1000;
                  final medium = constraints.maxWidth >= 650;
                  final columns = wide
                      ? 4
                      : medium
                      ? 2
                      : 2;

                  return CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // SliverToBoxAdapter(
                      //   child: Padding(
                      //     padding: EdgeInsets.fromLTRB(
                      //       wide ? 32 : 18,
                      //       20,
                      //       wide ? 32 : 18,
                      //       10,
                      //     ),
                      //     child: _Header(onRefresh: _refresh),
                      //   ),
                      // ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 32 : 18,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Overview',
                                style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Food producer intelligence at a glance',
                                style: TextStyle(
                                  color: Colors.blueGrey.shade600,
                                ),
                              ),
                              const SizedBox(height: 18),
                              GridView.count(
                                crossAxisCount: columns,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: wide
                                    ? 1.9
                                    : medium
                                    ? 1.75
                                    : 1.45,
                                children: [
                                  _MetricCard(
                                    title: 'Registered producers',
                                    value: _fmt(data.summary.totalProducers),
                                    icon: Icons.factory_outlined,
                                    tint: const Color(0xFFE8F1FF),
                                    accent: const Color(0xFF2864C5),
                                  ),
                                  _MetricCard(
                                    title: 'Verified producers',
                                    value: _fmt(data.summary.verifiedProducers),
                                    icon: Icons.verified_outlined,
                                    tint: const Color(0xFFE4F7ED),
                                    accent: _green,
                                  ),
                                  _MetricCard(
                                    title: 'Active producers',
                                    value: _fmt(data.summary.activeProducers),
                                    icon: Icons.storefront_outlined,
                                    tint: const Color(0xFFFFF2DD),
                                    accent: const Color(0xFFB86A10),
                                  ),
                                  _MetricCard(
                                    title: 'Food categories',
                                    value: _fmt(data.summary.categories),
                                    icon: Icons.category_outlined,
                                    tint: const Color(0xFFF0E9FF),
                                    accent: const Color(0xFF7751B8),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _sectionHeader(
                                'Production analytics',
                                'Real API records',
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Production trend',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: _navy,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  DropdownButton<String>(
                                    value: _period,
                                    underline: const SizedBox.shrink(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: '30 days',
                                        child: Text('30 days'),
                                      ),
                                      DropdownMenuItem(
                                        value: '6 months',
                                        child: Text('6 months'),
                                      ),
                                      DropdownMenuItem(
                                        value: '12 months',
                                        child: Text('12 months'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null)
                                        setState(() => _period = v);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _ProductionTrendCard(
                                points: _periodPoints(
                                  data.productionTrend,
                                  _period,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (wide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _BreakdownCard(
                                        title: 'Producers by category',
                                        points: data.categoryBreakdown,
                                        icon: Icons.category_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _BreakdownCard(
                                        title: 'Producers by region',
                                        points: data.regionBreakdown,
                                        icon: Icons.location_on_outlined,
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                _BreakdownCard(
                                  title: 'Producers by category',
                                  points: data.categoryBreakdown,
                                  icon: Icons.category_outlined,
                                ),
                                const SizedBox(height: 16),
                                _BreakdownCard(
                                  title: 'Producers by region',
                                  points: data.regionBreakdown,
                                  icon: Icons.location_on_outlined,
                                ),
                              ],
                              const SizedBox(height: 24),
                              _sectionHeader(
                                'Producer directory',
                                'Latest records',
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                onChanged: (value) =>
                                    setState(() => _search = value),
                                decoration: InputDecoration(
                                  hintText: 'Search producers or categories...',
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      if (matches.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No producers match your search.'),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 32 : 18,
                            0,
                            wide ? 32 : 18,
                            28,
                          ),
                          sliver: SliverList.separated(
                            itemCount: matches.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 9),
                            itemBuilder: (context, index) => _ProducerTile(
                              producer: matches[index],
                              onTap: widget.onSelectProducer == null
                                  ? null
                                  : () => widget.onSelectProducer!(
                                      matches[index],
                                    ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  List<DashboardPoint> _periodPoints(
    List<DashboardPoint> points,
    String period,
  ) {
    final count = period == '30 days'
        ? 1
        : period == '6 months'
        ? 6
        : 12;
    if (points.length <= count) return points;
    return points.sublist(points.length - count);
  }

  Widget _sectionHeader(String title, String subtitle) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: _navy,
          ),
        ),
      ),
      Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500),
      ),
    ],
  );

  String _fmt(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}

class _Header extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF17865B),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.eco_outlined, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nutritious Food',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10243A),
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Producer intelligence dashboard',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh dashboard',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color tint;
  final Color accent;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tint,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                size: 15,
                color: Colors.blueGrey.shade300,
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: Color(0xFF10243A),
              ),
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ProductionTrendCard extends StatelessWidget {
  final List<DashboardPoint> points;
  const _ProductionTrendCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 285,
      padding: const EdgeInsets.fromLTRB(16, 18, 20, 12),
      decoration: _cardDecoration(),
      child: points.isEmpty
          ? const _EmptyChart(
              message: 'No production trend data available.',
              detail:
                  'No production records were found for the selected period. ',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  points.last.unit == null
                      ? 'Production quantity'
                      : 'Production (${points.last.unit})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: const Color(0xFFEAF0F4),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            getTitlesWidget: (value, _) => Text(
                              _short(value),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (points.length / 5)
                                .ceilToDouble()
                                .clamp(1, 100)
                                .toDouble(),
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              if (i < 0 || i >= points.length)
                                return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  points[i].label,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            points.length,
                            (i) => FlSpot(i.toDouble(), points[i].value),
                          ),
                          isCurved: true,
                          color: const Color(0xFF17865B),
                          barWidth: 3,
                          dotData: FlDotData(show: points.length <= 12),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFF17865B).withOpacity(.10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _short(double value) {
    if (value.abs() >= 1000000)
      return '${(value / 1000000).toStringAsFixed(1)}m';
    if (value.abs() >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final List<DashboardPoint> points;
  final IconData icon;
  const _BreakdownCard({
    required this.title,
    required this.points,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final display = points.take(6).toList();
    final maxValue = display.fold<double>(
      0,
      (prev, e) => e.value > prev ? e.value : prev,
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF17865B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF10243A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (display.isEmpty)
            const _EmptyChart(
              message: 'No breakdown data available.',
              detail: 'Check the producer API response.',
            )
          else
            ...display.map((point) {
              final fraction = maxValue <= 0
                  ? 0.0
                  : (point.value / maxValue).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            point.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF3E5064),
                            ),
                          ),
                        ),
                        Text(
                          _format(point.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Color(0xFF10243A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFEDF2F5),
                        color: const Color(0xFF17865B),
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (display.isNotEmpty && display.first.unit == 'producers')
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Counts are based on producer records.',
                style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade500),
              ),
            ),
        ],
      ),
    );
  }

  String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

class _ProducerTile extends StatelessWidget {
  final Producer producer;
  final VoidCallback? onTap;
  const _ProducerTile({required this.producer, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F5ED),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.factory_outlined,
                  color: Color(0xFF17865B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            producer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10243A),
                            ),
                          ),
                        ),
                        if (producer.verified) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF17865B),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      producer.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                    if (producer.address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Colors.blueGrey.shade400,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              producer.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blueGrey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.blueGrey),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;
  final String detail;
  const _EmptyChart({required this.message, required this.detail});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.insert_chart_outlined,
            size: 32,
            color: Color(0xFF9AA9B7),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Color(0xFF526579),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8190A0)),
          ),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: Colors.blueGrey,
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load the dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: const Color(0xFFE8EDF2)),
);
