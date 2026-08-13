import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 12),
      Center(
        child: Container(
          width: 86,
          height: 86,
          decoration: const BoxDecoration(
            color: AppTheme.secondary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, size: 46, color: Colors.white),
        ),
      ),
      const SizedBox(height: 14),
      const Center(
        child: Text(
          'Guest User',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      const Center(child: Text('Sign in to save companies and preferences')),
      const SizedBox(height: 26),
      FilledButton(onPressed: () {}, child: const Text('Sign in')),
      const SizedBox(height: 18),
      Card(
        child: Column(
          children: const [
            ListTile(
              leading: Icon(Icons.favorite_border),
              title: Text('Saved companies'),
              trailing: Icon(Icons.chevron_right),
            ),
            ListTile(
              leading: Icon(Icons.notifications_none),
              title: Text('Notifications'),
              trailing: Icon(Icons.chevron_right),
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text('Settings'),
              trailing: Icon(Icons.chevron_right),
            ),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Help & support'),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    ],
  );
}
