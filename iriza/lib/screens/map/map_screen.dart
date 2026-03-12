// lib/screens/map/map_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/listing_provider.dart';
import '../../models/listing_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../utils/page_transitions.dart';
import '../listings/listing_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  ListingModel? _selectedListing;

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<Marker> _buildMarkers(List<ListingModel> listings) {
    return listings.map((listing) {
      return Marker(
        width: 40,
        height: 40,
        point: LatLng(listing.latitude, listing.longitude),
        child: GestureDetector(
          onTap: () => setState(() => _selectedListing = listing),
          child: Container(
            decoration: BoxDecoration(
              color: _categoryColor(listing.category),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                AppConstants.categoryIcons[listing.category] ?? '📍',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Hospitals':
        return Colors.red.shade400;
      case 'Cafés':
      case 'Restaurants':
        return Colors.orange.shade400;
      case 'Parks':
        return Colors.green.shade400;
      case 'Tourist Attractions':
        return Colors.purple.shade400;
      case 'Libraries':
        return Colors.cyan.shade400;
      case 'Police Stations':
        return Colors.blue.shade400;
      default:
        return Colors.yellow.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Consumer<ListingProvider>(
        builder: (context, provider, _) {
          final listings = provider.allListings;

          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                      AppConstants.kigaliLat, AppConstants.kigaliLng),
                  initialZoom: 13,
                  onTap: (_, __) => setState(() => _selectedListing = null),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.iriza',
                  ),
                  MarkerLayer(markers: _buildMarkers(listings)),
                ],
              ),
              // Top bar
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark.withValues(alpha:0.92),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_rounded,
                              color: AppTheme.accentOrange, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Map View',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withValues(alpha:0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${listings.length} places',
                              style: const TextStyle(
                                color: AppTheme.accentOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Zoom controls
              Positioned(
                bottom: _selectedListing != null ? 240 : 96,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_in',
                      onPressed: _zoomIn,
                      backgroundColor: AppTheme.cardDark,
                      child: const Icon(Icons.add_rounded,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_out',
                      onPressed: _zoomOut,
                      backgroundColor: AppTheme.cardDark,
                      child: const Icon(Icons.remove_rounded,
                          color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
              // Selected listing card
              if (_selectedListing != null)
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: _buildListingPreviewCard(_selectedListing!),
                ),
              // My location FAB
              Positioned(
                bottom: _selectedListing != null ? 168 : 24,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'map_my_location',
                  onPressed: () {
                    _mapController.move(
                      LatLng(AppConstants.kigaliLat, AppConstants.kigaliLng),
                      13,
                    );
                  },
                  backgroundColor: AppTheme.cardDark,
                  child: const Icon(Icons.my_location_rounded,
                      color: AppTheme.textPrimary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListingPreviewCard(ListingModel listing) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        FadePageRoute(
            builder: (_) => ListingDetailScreen(listing: listing)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryDark.withValues(alpha:0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  AppConstants.categoryIcons[listing.category] ?? '📍',
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.starYellow, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        listing.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            color: AppTheme.starYellow, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        listing.category,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'View',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

