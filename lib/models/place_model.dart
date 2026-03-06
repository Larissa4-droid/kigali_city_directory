class Place {
  final String id;
  final String name;
  final String category;
  final String description;
  final double latitude;
  final double longitude;

  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  // Convert Firestore document to a Place object
  factory Place.fromMap(Map<String, dynamic> map, String id) {
    return Place(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }
}