import 'package:flutter/material.dart';

import '../../theme/app_style.dart';
import '../services/location_search_service.dart';

class StationLocationSearchDelegate
    extends SearchDelegate<LocationSearchResult?> {
  StationLocationSearchDelegate({required this.service})
    : super(
        searchFieldLabel: 'Search a city, place, or address',
        keyboardType: TextInputType.streetAddress,
        textInputAction: TextInputAction.search,
      );

  final LocationSearchService service;
  String? _activeQuery;
  Future<List<LocationSearchResult>>? _activeSearch;

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        foregroundColor: AppStyle.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppStyle.muted),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: 'Clear location search',
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
        icon: const Icon(Icons.close_rounded),
      ),
    IconButton(
      tooltip: 'Submit location search',
      onPressed: () => showResults(context),
      icon: const Icon(Icons.search_rounded),
    ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: 'Close location search',
    onPressed: () => close(context, null),
    icon: const BackButtonIcon(),
  );

  @override
  Widget buildSuggestions(BuildContext context) => _SearchNotice(
    icon: Icons.travel_explore_rounded,
    title: query.trim().isEmpty
        ? 'Search for another location'
        : 'Press search to find “${query.trim()}”',
    message: query.trim().isEmpty
        ? 'The map stays centered on CST, Bhutan until you select a result.'
        : 'Results appear only after you submit, reducing unnecessary location requests.',
  );

  @override
  Widget buildResults(BuildContext context) {
    final submitted = query.trim();
    if (submitted.length < 2) {
      return const _SearchNotice(
        icon: Icons.manage_search_rounded,
        title: 'Enter a location',
        message: 'Type at least two characters, then press search.',
      );
    }
    if (_activeQuery != submitted) {
      _activeQuery = submitted;
      _activeSearch = service.search(submitted);
    }
    return FutureBuilder<List<LocationSearchResult>>(
      future: _activeSearch,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: Semantics(
              label: 'Searching locations',
              child: const CircularProgressIndicator(color: AppStyle.green),
            ),
          );
        }
        if (snapshot.hasError) {
          final message = snapshot.error is LocationSearchException
              ? (snapshot.error! as LocationSearchException).message
              : 'Location search failed. Please try again.';
          return _SearchNotice(
            icon: Icons.cloud_off_outlined,
            title: 'Could not search locations',
            message: message,
            actionLabel: 'Retry',
            onAction: () {
              _activeQuery = null;
              showResults(context);
            },
          );
        }
        final results = snapshot.data ?? const [];
        if (results.isEmpty) {
          return const _SearchNotice(
            icon: Icons.location_off_outlined,
            title: 'No locations found',
            message: 'Try a city, landmark, or more complete address.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: results.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppStyle.paleGreen,
                foregroundColor: AppStyle.darkGreen,
                child: Icon(Icons.location_on_outlined),
              ),
              title: Text(
                result.label,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.north_west_rounded),
              onTap: () => close(context, result),
            );
          },
        );
      },
    );
  }
}

class _SearchNotice extends StatelessWidget {
  const _SearchNotice({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppStyle.green, size: 42),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppStyle.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppStyle.muted, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    ),
  );
}
