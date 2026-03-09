import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Essential import

// ... inside your build method
FlutterMap(
  options: const MapOptions(
    initialCenter: LatLng(-1.9441, 30.0619), // Changed from 'center'
    initialZoom: 13.0,                       // Changed from 'zoom'
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.app',
    ),
    MarkerLayer(
      markers: [
        Marker(
          point: LatLng(-1.9441, 30.0619),
          width: 80,
          height: 80,
          child: Icon(Icons.location_on, color: Colors.red), // Use 'child', not 'builder'
        ),
      ],
    ),
  ],
)