// lib/screens/listings/my_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/listing_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/page_transitions.dart';
import '../../widgets/listing_card.dart';
import 'listing_detail_screen.dart';
import 'add_edit_listing_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  Future<void> _confirmDelete(BuildContext context, String id) async {
    final provider = context.read<ListingProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Delete Listing',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Are you sure you want to delete this listing? This cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      print('Deleting listing: $id');
      final success = await provider.deleteListing(id);
      if (!mounted) return;
      if (success) {
        print('Listing deleted successfully');
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Listing deleted'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        print('Failed to delete listing');
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Failed to delete listing'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bookmarks',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Consumer<ListingProvider>(
                    builder: (context, provider, _) {
                      return Row(
                        children: [
                          const Text('Bookmarks',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13)),
                          const SizedBox(width: 8),
                          Switch(
                            value: true,
                            onChanged: (_) {},
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBookmarkedListings()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'my_listings_add_listing',
        onPressed: () => Navigator.push(
          context,
          FadePageRoute(builder: (_) => const AddEditListingScreen()),
        ),
        backgroundColor: AppTheme.accentOrange,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildBookmarkedListings() {
    return Consumer<ListingProvider>(
      builder: (context, provider, _) {
        final bookmarked = provider.bookmarkedListings;
        print('Bookmarked listings count: ${bookmarked.length}');
        if (bookmarked.isEmpty) {
          return _buildEmpty(
            icon: Icons.bookmark_border_rounded,
            title: 'No saved places yet',
            subtitle: 'Bookmark listings to find them here',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: bookmarked.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final listing = bookmarked[i];
            return ListingCard(
              listing: listing,
              isBookmarked: true,
              onTap: () => Navigator.push(
                context,
                FadePageRoute(
                  builder: (_) => ListingDetailScreen(listing: listing),
                ),
              ),
              onBookmarkTap: () {
                print('Toggling bookmark for: ${listing.id}');
                provider.toggleBookmark(listing.id);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}