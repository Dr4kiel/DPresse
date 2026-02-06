import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../providers/search_provider.dart';

class SearchFilters extends ConsumerWidget {
  const SearchFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Search in title toggle
          FilterChip(
            label: const Text('Titre uniquement'),
            selected: searchState.searchInTitle,
            onSelected: (value) {
              ref.read(searchProvider.notifier).setSearchInTitle(value);
            },
          ),
          // Date range filters
          ..._dateRangeChips(context, ref, searchState.dateRange, theme),
        ],
      ),
    );
  }

  List<Widget> _dateRangeChips(
    BuildContext context,
    WidgetRef ref,
    int currentRange,
    ThemeData theme,
  ) {
    final ranges = {
      AppConstants.dateRangeWeek: 'Semaine',
      AppConstants.dateRangeMonth: 'Mois',
      AppConstants.dateRangeYear: 'Année',
      AppConstants.dateRangeAll: 'Tout',
    };

    return ranges.entries.map((entry) {
      return ChoiceChip(
        label: Text(entry.value),
        selected: currentRange == entry.key,
        onSelected: (selected) {
          if (selected) {
            ref.read(searchProvider.notifier).setDateRange(entry.key);
          }
        },
      );
    }).toList();
  }
}
