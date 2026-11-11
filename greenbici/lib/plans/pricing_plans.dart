import 'package:flutter/material.dart';

import '../theme/app_style.dart';

/// Shared GreenBici plan prices shown on Home and Profile.
class PlanPrice {
  const PlanPrice(this.label, this.price, {this.canSubscribe = true});

  final String label;
  final String price;
  final bool canSubscribe;
}

class PlanGroup {
  const PlanGroup({required this.title, required this.prices, this.note});

  final String title;
  final String? note;
  final List<PlanPrice> prices;

  List<PlanPrice> get subscribablePrices =>
      prices.where((price) => price.canSubscribe).toList(growable: false);
}

/// The pricing structure used by Manage Plan and Manage Subscription.
const greenBiciPlanGroups = <PlanGroup>[
  PlanGroup(
    title: 'Short-Term Plans',
    prices: [PlanPrice('1 Day', 'Nu. 499'), PlanPrice('7 Days', 'Nu. 1,499')],
  ),
  PlanGroup(
    title: 'Long-Term Plans',
    prices: [
      PlanPrice('Monthly', 'Nu. 5,999'),
      PlanPrice('1 Year', 'Nu. 4,999'),
    ],
  ),
  PlanGroup(
    title: 'Late Return Penalties (Over 30 Minutes)',
    prices: [
      PlanPrice('First Hour', 'Nu. 55', canSubscribe: false),
      PlanPrice('Each Following Hour', 'Nu. 220', canSubscribe: false),
    ],
  ),
  PlanGroup(
    title: '108 Chorten Subscription',
    note: 'Applicable Stations: CH1, CH65, and CH108',
    prices: [
      PlanPrice('2-Hour Subscription', 'Nu. 300'),
      PlanPrice('Overtime Penalty', 'Nu. 200 per hour', canSubscribe: false),
    ],
  ),
];

/// Page body shown after Manage Plan or Manage Subscription is opened.
class PricingPlansBody extends StatelessWidget {
  const PricingPlansBody({super.key, required this.title, this.onDark = false});

  final String title;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark ? Colors.white : AppStyle.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: titleColor),
          ),
        ),
        const SizedBox(height: 12),
        PricingPlans(onDark: onDark),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Fades between a screen's main content and its pricing list.
class MainContentSwitch extends StatelessWidget {
  const MainContentSwitch({
    super.key,
    required this.showPlans,
    required this.plans,
    required this.child,
  });

  final bool showPlans;
  final Widget plans;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.hardEdge,
        children: [
          if (current case final Widget current) current,
          for (final outgoing in previous)
            Positioned(top: 0, left: 0, right: 0, child: outgoing),
        ],
      ),
      child: showPlans ? plans : child,
    );
  }
}

/// Renders [greenBiciPlanGroups] as aligned cards.
///
/// [onDark] matches the Profile subscription banner. Home uses the light cards.
class PricingPlans extends StatelessWidget {
  const PricingPlans({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final columns = constraints.maxWidth >= 640 && textScale <= 1.35 ? 2 : 1;
      final cards = [
        for (final group in greenBiciPlanGroups)
          _PlanGroupCard(group: group, onDark: onDark),
      ];
      if (columns == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              if (index > 0) const SizedBox(height: 10),
              cards[index],
            ],
          ],
        );
      }
      final rows = <Widget>[];
      for (var index = 0; index < cards.length; index += 2) {
        final hasPair = index + 1 < cards.length;
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[index]),
                const SizedBox(width: 10),
                Expanded(child: hasPair ? cards[index + 1] : const SizedBox()),
              ],
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            rows[index],
          ],
        ],
      );
    },
  );
}

class _PlanGroupCard extends StatelessWidget {
  const _PlanGroupCard({required this.group, required this.onDark});

  final PlanGroup group;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark ? Colors.white : AppStyle.ink;
    final bodyColor = onDark ? const Color(0xF2FFFFFF) : AppStyle.muted;
    final priceColor = onDark ? Colors.white : AppStyle.darkGreen;
    final card = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            group.title,
            style: TextStyle(
              color: titleColor,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (group.note != null) ...[
            const SizedBox(height: 6),
            Text(
              group.note!,
              style: TextStyle(color: bodyColor, fontSize: 12, height: 1.35),
            ),
          ],
          const SizedBox(height: 8),
          for (var index = 0; index < group.prices.length; index++) ...[
            if (index > 0) const SizedBox(height: 6),
            _PriceRow(
              price: group.prices[index],
              labelColor: bodyColor,
              priceColor: priceColor,
            ),
          ],
        ],
      ),
    );
    final decoration = BoxDecoration(
      color: onDark ? const Color(0x29FFFFFF) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: onDark ? const Color(0x33FFFFFF) : AppStyle.border,
      ),
    );
    if (group.subscribablePrices.isEmpty) {
      return DecoratedBox(decoration: decoration, child: card);
    }
    return Semantics(
      button: true,
      label: 'View ${group.title} subscriptions',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: decoration,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => showPlanSubscriptionSheet(context, group: group),
            child: card,
          ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.price,
    required this.labelColor,
    required this.priceColor,
  });

  final PlanPrice price;
  final Color labelColor;
  final Color priceColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 2,
          children: [
            Text(
              price.label,
              style: TextStyle(color: labelColor, fontSize: 13, height: 1.3),
            ),
            Text(
              price.price,
              style: TextStyle(
                color: priceColor,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows all purchasable plans in the selected category.
void showPlanSubscriptionSheet(
  BuildContext context, {
  required PlanGroup group,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _PlanSubscriptionSheet(group: group),
  );
}

class _PlanSubscriptionSheet extends StatelessWidget {
  const _PlanSubscriptionSheet({required this.group});

  final PlanGroup group;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3AA78D), Color(0xFF218C89)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: AppStyle.darkGreen,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    group.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (group.note != null) ...[
              const SizedBox(height: 8),
              Text(
                group.note!,
                style: const TextStyle(color: Color(0xEFFFFFFF), fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            for (
              var index = 0;
              index < group.subscribablePrices.length;
              index++
            ) ...[
              if (index > 0) const SizedBox(height: 12),
              _SubscriptionPlanCard(plan: group.subscribablePrices[index]),
            ],
          ],
        ),
      ),
    ),
  );
}

class _SubscriptionPlanCard extends StatelessWidget {
  const _SubscriptionPlanCard({required this.plan});

  final PlanPrice plan;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0x1FFFFFFF),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x33FFFFFF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GreenBici ${plan.label}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        const _Benefit(text: 'Unlimited 30-minute rides'),
        const SizedBox(height: 8),
        const _Benefit(text: 'Priority bike access'),
        const SizedBox(height: 16),
        Text(
          plan.price,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: ValueKey('subscribe-${plan.label}'),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      '${plan.label} selected. Subscription checkout is coming soon.',
                    ),
                  ),
                );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppStyle.darkGreen,
              minimumSize: const Size(48, 54),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            child: const Text('Subscribe'),
          ),
        ),
      ],
    ),
  );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.check_rounded, color: Colors.white, size: 22),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    ],
  );
}
