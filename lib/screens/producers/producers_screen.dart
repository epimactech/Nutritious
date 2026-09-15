import 'package:flutter/material.dart';
import '../../models/producer.dart';
import '../../widgets/producer_card.dart';

class ProducersScreen extends StatefulWidget {
  final List<Producer> producers;
  final ValueChanged<Producer> onSelect;
  const ProducersScreen({
    super.key,
    required this.producers,
    required this.onSelect,
  });

  @override
  State<ProducersScreen> createState() => _ProducersScreenState();
}

class _ProducersScreenState extends State<ProducersScreen> {
  String query = '';
  String category = 'All';

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      ...{for (final c in widget.producers) c.category},
    ];
    final filtered = widget.producers.where((c) {
      final matchesText =
          c.name.toLowerCase().contains(query.toLowerCase()) ||
          c.category.toLowerCase().contains(query.toLowerCase());
      return matchesText && (category == 'All' || c.category == category);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search producer...',
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ChoiceChip(
              label: Text(categories[i]),
              selected: category == categories[i],
              onSelected: (_) => setState(() => category = categories[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => Card(
              child: ProducerCard(
                producer: filtered[i],
                onTap: () => widget.onSelect(filtered[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
