// lib/screens/listings/listing_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/listing_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../utils/page_transitions.dart';
import 'package:uuid/uuid.dart';
import 'add_edit_listing_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  final ListingModel listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final MapController _mapController = MapController();
  double _userRating = 0;
  final _reviewController = TextEditingController();
  bool _submittingReview = false;

  @override
  void dispose() {
    _reviewController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _openDirections() async {
    final url = Uri.parse(
      'https://www.openstreetmap.org/?mlat=${widget.listing.latitude}&mlon=${widget.listing.longitude}&zoom=15',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone() async {
    final url = Uri.parse('tel:${widget.listing.contactNumber}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _confirmDelete() async {
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
      final provider = context.read<ListingProvider>();
      final success = await provider.deleteListing(widget.listing.id);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Listing deleted successfully'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
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

  Future<void> _submitReview() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _submittingReview = true);
    final auth = context.read<AuthProvider>();
    
    final user = auth.user;
    if (user == null) {
      setState(() => _submittingReview = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return;
    }
    
    final userId = user.uid;
    final userName = user.displayName?.isNotEmpty == true 
        ? user.displayName 
        : (user.email?.split('@').first ?? 'Anonymous');
        
    final review = ReviewModel(
      id: const Uuid().v4(),
      listingId: widget.listing.id,
      userId: userId,
      userName: userName,
      rating: _userRating,
      comment: _reviewController.text.trim(),
      createdAt: DateTime.now(),
    );
    await context.read<ListingProvider>().addReview(review);
    _reviewController.clear();
    setState(() {
      _userRating = 0;
      _submittingReview = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isOwner = auth.user?.uid == widget.listing.createdBy;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: CustomScrollView(
        slivers: [
          // App bar with map
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withValues(alpha:0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (isOwner)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark.withValues(alpha:0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    FadePageRoute(
                      builder: (_) =>
                          AddEditListingScreen(listing: widget.listing),
                    ),
                  ),
                ),
              if (isOwner)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark.withValues(alpha:0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorRed),
                  ),
                  onPressed: _confirmDelete,
                )
              else
                Consumer<ListingProvider>(
                  builder: (context, provider, _) {
                    final bookmarked = provider.isBookmarked(widget.listing.id);
                    return IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryDark.withValues(alpha:0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          bookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 18,
                          color: bookmarked
                              ? AppTheme.accentOrange
                              : AppTheme.textPrimary,
                        ),
                      ),
                      onPressed: () =>
                          provider.toggleBookmark(widget.listing.id),
                    );
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                      widget.listing.latitude, widget.listing.longitude),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.iriza',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 50,
                        height: 50,
                        point: LatLng(
                            widget.listing.latitude, widget.listing.longitude),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              AppConstants.categoryIcons[widget.listing.category] ?? '📍',
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.listing.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  AppConstants.categoryIcons[
                                          widget.listing.category] ??
                                      '📍',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.listing.category,
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.near_me_outlined,
                                    size: 14, color: AppTheme.textMuted),
                                const SizedBox(width: 2),
                                Text(
                                  widget.listing.distanceText,
                                  style: const TextStyle(
                                      color: AppTheme.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppTheme.starYellow, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                widget.listing.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${widget.listing.reviewCount} reviews',
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Description
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Text(
                      widget.listing.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info cards
                  _buildInfoRow(
                      Icons.location_on_outlined, widget.listing.address),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      Icons.phone_outlined, widget.listing.contactNumber),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openDirections,
                          icon: const Icon(Icons.navigation_rounded, size: 18),
                          label: const Text('Get Directions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _callPhone,
                        icon: const Icon(Icons.call_outlined, size: 18),
                        label: const Text('Call'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: AppTheme.dividerColor),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Reviews section
                  const Text(
                    'Reviews',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add review
                  _buildAddReview(),
                  const SizedBox(height: 16),
                  // Reviews list
                  StreamBuilder<List<ReviewModel>>(
                    stream: context
                        .read<ListingProvider>()
                        .streamReviews(widget.listing.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No reviews yet. Be the first!',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        );
                      }
                      return Column(
                        children: snapshot.data!
                            .map((review) => _buildReviewCard(review))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildAddReview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate this service',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _userRating = i + 1.0),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    i < _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppTheme.starYellow,
                    size: 28,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reviewController,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share your experience...',
              hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submittingReview ? null : _submitReview,
              child: _submittingReview
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Review'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.2),
                child: Text(
                  review.userName[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppTheme.starYellow,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _timeAgo(review.createdAt),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }
}

