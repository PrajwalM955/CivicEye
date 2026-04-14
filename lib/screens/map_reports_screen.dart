import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapReportsScreen extends StatefulWidget {
  const MapReportsScreen({super.key});

  @override
  State<MapReportsScreen> createState() => _MapReportsScreenState();
}

class _MapReportsScreenState extends State<MapReportsScreen> {
  MapController? mapController;

  List<Map<String, dynamic>> getDummyMarkers() {
    return [
      {
        'lat': 12.9716,
        'lng': 77.5946,
        'title': 'Pothole on MG Road',
        'severity': 'High',
        'description': 'Large pothole affecting traffic',
      },
      {
        'lat': 12.9780,
        'lng': 77.6033,
        'title': 'Broken Streetlight on Brigade Road',
        'severity': 'High',
        'description': 'Streetlight out, causing safety concerns at night',
      },
      {
        'lat': 12.9650,
        'lng': 77.5870,
        'title': 'Overflowing Garbage Bin near Cubbon Park',
        'severity': 'High',
        'description': 'Bin overflowing, attracting pests and health hazards',
      },
      {
        'lat': 12.9830,
        'lng': 77.5950,
        'title': 'Cracked Pavement on Residency Road',
        'severity': 'High',
        'description': 'Severe cracks posing tripping hazards for pedestrians',
      },
      {
        'lat': 12.9600,
        'lng': 77.6000,
        'title': 'Illegal Parking Blocking Fire Hydrant',
        'severity': 'High',
        'description': 'Vehicle blocking emergency access, potential fire risk',
      },
    ];
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color _getHeatZoneColor(String severity) {
    return _getSeverityColor(severity);
  }

  void _showMarkerInfo(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['title'] ?? 'Civic Issue',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            /// BADGE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getSeverityColor(data['severity']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data['severity'].toUpperCase(),
                style: TextStyle(
                  color: _getSeverityColor(data['severity']),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(data['description'] ?? ''),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B61FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: bg,

      body: Stack(
        children: [
          /// MAP
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .snapshots(),
            builder: (context, snapshot) {
              final allMarkers = <Marker>[];
              final allHeatZones = <CircleMarker>[];

              final dummyData = getDummyMarkers();

              /// DUMMY MARKERS
              for (var marker in dummyData) {
                final point = LatLng(marker['lat'], marker['lng']);

                allHeatZones.add(
                  CircleMarker(
                    point: point,
                    radius: 250,
                    useRadiusInMeter: true,
                    color: _getHeatZoneColor(
                      marker['severity'],
                    ).withOpacity(0.2),
                  ),
                );

                allMarkers.add(
                  Marker(
                    point: point,
                    width: 45,
                    height: 45,
                    child: GestureDetector(
                      onTap: () => _showMarkerInfo(marker),
                      child: _markerUI(marker['severity']),
                    ),
                  ),
                );
              }

              /// FIRESTORE MARKERS
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;

                  if (data['latitude'] != null && data['longitude'] != null) {
                    final point = LatLng(
                      (data['latitude'] as num).toDouble(),
                      (data['longitude'] as num).toDouble(),
                    );

                    allMarkers.add(
                      Marker(
                        point: point,
                        width: 45,
                        height: 45,
                        child: GestureDetector(
                          onTap: () => _showMarkerInfo(data),
                          child: _markerUI(data['severity'] ?? "medium"),
                        ),
                      ),
                    );
                  }
                }
              }

              return FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(12.9716, 77.5946),
                  initialZoom: 12,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  /// ✅ FIXED TILE LAYER
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.civiceye',
                  ),

                  CircleLayer(circles: allHeatZones),
                  MarkerLayer(markers: allMarkers),
                ],
              );
            },
          ),

          /// HEADER
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Issues Map",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// LEGEND
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _legend("Low", Colors.green),
                  _legend("Medium", Colors.orange),
                  _legend("High", Colors.red),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _markerUI(String severity) {
    final color = _getSeverityColor(severity);

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 10)],
      ),
      child: const Icon(Icons.location_on, color: Colors.white, size: 22),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
