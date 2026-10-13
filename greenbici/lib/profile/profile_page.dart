import 'package:flutter/material.dart';

import '../navbar/top_nav.dart';
import '../theme/app_card.dart';
import '../theme/app_style.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    this.displayName = 'Alex Morgan',
    this.onSearch,
  });

  final String displayName;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth < 360 ? 14 : 20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TopNav(title: 'My Profile', onSearch: onSearch),
                _identity(context),
                const SizedBox(height: 18),
                _subscription(context),
                const SizedBox(height: 18),
                _account(context),
                const SizedBox(height: 18),
                _settings(context),
                const SizedBox(height: 18),
                _signOut(context),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _identity(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 420 ||
          MediaQuery.textScalerOf(context).scale(14) > 21;
      final emailName = displayName.toLowerCase().replaceAll(' ', '.');
      final avatar = CircleAvatar(
        radius: 46,
        backgroundColor: AppStyle.paleGreen,
        child: Text(
          _initials,
          style: const TextStyle(
            color: AppStyle.darkGreen,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      final details = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '$emailName@email.com',
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppStyle.muted, fontSize: 16),
          ),
        ],
      );
      final edit = _iconAction(
        context,
        Icons.edit_rounded,
        'Edit profile',
        'Profile editing is coming soon.',
      );
      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [avatar, const Spacer(), edit]),
            const SizedBox(height: 14),
            details,
          ],
        );
      }
      return Row(
        children: [
          avatar,
          const SizedBox(width: 18),
          Expanded(child: details),
          edit,
        ],
      );
    },
  );

  Widget _subscription(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF319B7E), Color(0xFF268B87)],
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x180E2E0A),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final narrow =
            constraints.maxWidth < 540 ||
            MediaQuery.textScalerOf(context).scale(14) > 21;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 27,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: AppStyle.darkGreen,
                    size: 30,
                  ),
                ),
                const Text(
                  'GreenBici Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0x3375D779),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '● Active',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              '✓  Unlimited 30-minute rides',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              '✓  Priority bike access',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        );
        final price = Column(
          crossAxisAlignment: narrow
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.end,
          children: [
            const Text(
              'Nu. 299 / month',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: () => _message(
                context,
                'Subscription management is not connected yet.',
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppStyle.darkGreen,
                side: BorderSide.none,
              ),
              child: const Text(
                'Manage Subscription',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
        return narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [details, const SizedBox(height: 18), price],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: details),
                  price,
                ],
              );
      },
    ),
  );

  Widget _account(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        _detailRow(Icons.phone_rounded, 'Phone', '+975 17 123 456'),
        const SizedBox(height: 12),
        _detailRow(Icons.location_on_outlined, 'Location', 'Thimphu'),
      ],
    ),
  );

  Widget _detailRow(IconData icon, String label, String value) => Row(
    children: [
      CircleAvatar(
        radius: 20,
        backgroundColor: AppStyle.paleGreen,
        child: Icon(icon, color: AppStyle.green, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppStyle.muted),
            ),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _settings(BuildContext context) {
    const rows = [
      (Icons.person_outline_rounded, 'Personal information'),
      (Icons.pedal_bike_rounded, 'Ride history'),
      (Icons.credit_card_outlined, 'Payment methods'),
      (Icons.notifications_none_rounded, 'Notifications & preferences'),
      (Icons.shield_outlined, 'Privacy & security'),
      (Icons.help_outline_rounded, 'Help & support'),
      (Icons.eco_outlined, 'About GreenBici'),
    ];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          for (final row in rows) _settingRow(context, row.$1, row.$2),
        ],
      ),
    );
  }

  Widget _settingRow(BuildContext context, IconData icon, String label) =>
      InkWell(
        onTap: () => _message(context, '$label is not connected yet.'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppStyle.border)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppStyle.paleGreen,
                child: Icon(icon, color: AppStyle.darkGreen, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 15)),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppStyle.muted),
            ],
          ),
        ),
      );

  Widget _signOut(BuildContext context) => AppCard(
    onTap: () => _message(context, 'Sign out is not connected yet.'),
    child: const Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFFFEEEE),
          child: Icon(Icons.logout_rounded, color: Color(0xFFC44242)),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Text(
            'Sign out',
            style: TextStyle(
              color: Color(0xFFC44242),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _iconAction(
    BuildContext context,
    IconData icon,
    String label,
    String message,
  ) => IconButton(
    onPressed: () => _message(context, message),
    tooltip: label,
    icon: CircleAvatar(
      backgroundColor: AppStyle.paleGreen,
      child: Icon(icon, color: AppStyle.green, size: 20),
    ),
  );
  void _message(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  String get _initials => displayName
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((part) => part[0])
      .join()
      .toUpperCase();
}
