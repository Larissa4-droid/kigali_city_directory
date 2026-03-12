// lib/widgets/listing_card.dart
import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../utils/app_theme.dart';
import '../utils/app_constants.dart';

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback? onBookmarkTap;
  final bool showActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ListingCard({
    super.key,
    required this.listing,
    required this.isBookmarked,
    required this.onTap,
    this.onBookmarkTap,
    this.showActions = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor, width: 1),
        ),
        child: Row(
          children: [
            // Category icon container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.secondaryDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  AppConstants.categoryIcons[listing.category] ?? '📍',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildRating(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildCategoryChip(),
                      const SizedBox(width: 8),
                      const Icon(Icons.near_me_outlined,
                          size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 2),
                      Text(
                        listing.distanceText,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    listing.description,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action buttons
            Column(
              children: [
                if (onBookmarkTap != null)
                  GestureDetector(
                    onTap: onBookmarkTap,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        key: ValueKey(isBookmarked),
                        color: isBookmarked
                            ? AppTheme.accentOrange
                            : AppTheme.textMuted,
                        size: 22,
                      ),
                    ),
                  ),
                if (showActions) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(Icons.edit_outlined,
                        color: AppTheme.accentBlue, size: 20),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline,
                        color: AppTheme.errorRed, size: 20),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: AppTheme.starYellow, size: 14),
        const SizedBox(width: 2),
        Text(
          listing.rating.toStringAsFixed(1),
          style: const TextStyle(
            color: AppTheme.starYellow,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.chipBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        listing.category,
        style: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}