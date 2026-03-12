// lib/screens/directory/directory_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/listing_card.dart';
import '../listings/listing_detail_screen.dart';
import '../listings/add_edit_listing_screen.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                color: AppTheme.accentOrange, size: 18),
                            SizedBox(width: 4),
                            Text(
                              'Kigali City',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Services & Places Directory',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.cardDark,
                    child: Text(
                      (auth.user?.displayName?.isNotEmpty ?? false)
                          ? auth.user!.displayName![0].toUpperCase()
                          : ((auth.user?.email?.isNotEmpty ?? false)
                              ? auth.user!.email![0].toUpperCase()
                              : 'U'),
                      style: const TextStyle(
                          color: AppTheme.accentOrange,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textPrimary),
                onChanged: (v) => context.read<ListingProvider>().setSearchQuery(v),
                decoration: InputDecoration(
                  hintText: 'Search for a service',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            context.read<ListingProvider>().setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Category filters
            SizedBox(
              height: 40,
              child: Consumer<ListingProvider>(
                builder: (context, provider, _) {
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: AppConstants.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = AppConstants.categories[i];
                      final isSelected = provider.selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => provider.setCategory(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.accentBlue
                                : AppTheme.chipBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.accentBlue
                                  : AppTheme.dividerColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Section title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Consumer<ListingProvider>(
                builder: (context, provider, _) {
                  return Row(
                    children: [
                      Text(
                        provider.searchQuery.isEmpty
                            ? 'Near You'
                            : 'Search Results',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${provider.filteredListings.length}',
                          style: const TextStyle(
                            color: AppTheme.accentOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Listings
            Expanded(
              child: Consumer<ListingProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.accentOrange),
                    );
                  }
                  if (provider.filteredListings.isEmpty) {
                    return _buildEmpty(provider.searchQuery.isNotEmpty);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: provider.filteredListings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final listing = provider.filteredListings[i];
                      return ListingCard(
                        listing: listing,
                        isBookmarked: provider.isBookmarked(listing.id),
                        onTap: () => Navigator.push(
                          context,
                          FadePageRoute(
                            builder: (_) => ListingDetailScreen(listing: listing),
                          ),
                        ),
                        onBookmarkTap: () =>
                            provider.toggleBookmark(listing.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'directory_add_listing',
        onPressed: () => Navigator.push(
          context,
          FadePageRoute(
              builder: (_) => const AddEditListingScreen()),
        ),
        backgroundColor: AppTheme.accentOrange,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty(bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off_rounded : Icons.location_off_outlined,
            color: AppTheme.textMuted,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No results found' : 'No listings yet',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch
                ? 'Try a different search term'
                : 'Be the first to add a listing!',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}