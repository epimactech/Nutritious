import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.eco, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'NFood',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            _item(Icons.map_outlined, 'Map', 0),
            _item(Icons.apartment_outlined, 'Producers', 1),
            _item(Icons.person_outline, 'Account', 2),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'Discover healthier businesses near you.',
                style: TextStyle(color: Colors.grey.shade600, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, int index) {
    final selected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppTheme.primary.withValues(alpha: .09),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: selected ? AppTheme.primary : Colors.grey.shade700,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppTheme.primary : Colors.grey.shade800,
          ),
        ),
        onTap: () => onSelected(index),
      ),
    );
  }
}
