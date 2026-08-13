import 'package:flutter/material.dart';
import '../../models/company.dart';
import '../../widgets/company_card.dart';

class CompaniesScreen extends StatefulWidget {
  final List<Company> companies;
  final ValueChanged<Company> onSelect;
  const CompaniesScreen({
    super.key,
    required this.companies,
    required this.onSelect,
  });

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  String query = '';
  String category = 'All';

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      ...{for (final c in widget.companies) c.category},
    ];
    final filtered = widget.companies.where((c) {
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
              hintText: 'Search companies...',
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
              child: CompanyCard(
                company: filtered[i],
                onTap: () => widget.onSelect(filtered[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
