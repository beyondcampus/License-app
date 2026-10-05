import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../state/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _metadataValue(AuthProvider auth, String key, String fallback) {
    final value = auth.user?.userMetadata?[key]?.toString().trim();
    return value == null || value.isEmpty ? fallback : value;
  }

  Future<void> _signOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your saved progress will remain in your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (shouldSignOut != true || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    await auth.signOut();
    if (!context.mounted || auth.error != null) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider?>();
    final name = auth == null
        ? AppStrings.appName
        : _metadataValue(auth, 'full_name', auth.user?.email ?? AppStrings.appName);
    final phone = auth == null
        ? 'Not available'
        : _metadataValue(auth, 'phone', 'Not provided');
    final email = auth?.user?.email ?? 'Not available';
    final initial = name.isEmpty ? 'E' : name[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 42,
            child: Text(initial, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(name, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 28),
          _ProfileRow(icon: Icons.person_outline, label: 'Name', value: name),
          _ProfileRow(icon: Icons.email_outlined, label: 'Email', value: email),
          _ProfileRow(icon: Icons.phone_outlined, label: 'Phone', value: phone),
          if (auth != null) ...[
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: auth.isBusy ? null : () => _signOut(context),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Text(
                auth.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
