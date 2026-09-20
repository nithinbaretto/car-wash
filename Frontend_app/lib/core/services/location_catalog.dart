import 'dart:math';

class PlacePin {
  const PlacePin({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });

  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
}

abstract final class LocationCatalog {
  static const bengaluru = PlacePin(
    title: 'Bengaluru',
    subtitle: 'City centre',
    latitude: 12.9716,
    longitude: 77.5946,
  );

  static const areas = <PlacePin>[
    PlacePin(
      title: 'Koramangala',
      subtitle: '5th Block, Bengaluru',
      latitude: 12.9352,
      longitude: 77.6245,
    ),
    PlacePin(
      title: 'Indiranagar',
      subtitle: '100 Feet Road, Bengaluru',
      latitude: 12.9784,
      longitude: 77.6408,
    ),
    PlacePin(
      title: 'HSR Layout',
      subtitle: 'Sector 4, Bengaluru',
      latitude: 12.9121,
      longitude: 77.6446,
    ),
    PlacePin(
      title: 'Whitefield',
      subtitle: 'ITPL Main Road, Bengaluru',
      latitude: 12.9698,
      longitude: 77.7499,
    ),
    PlacePin(
      title: 'Jayanagar',
      subtitle: '4th Block, Bengaluru',
      latitude: 12.9250,
      longitude: 77.5938,
    ),
    PlacePin(
      title: 'MG Road',
      subtitle: 'Central Bengaluru',
      latitude: 12.9758,
      longitude: 77.6060,
    ),
    PlacePin(
      title: 'Electronic City',
      subtitle: 'Phase 1, Bengaluru',
      latitude: 12.8456,
      longitude: 77.6603,
    ),
    PlacePin(
      title: 'Malleshwaram',
      subtitle: '8th Cross, Bengaluru',
      latitude: 13.0035,
      longitude: 77.5640,
    ),
    PlacePin(
      title: 'Marathahalli',
      subtitle: 'Outer Ring Road, Bengaluru',
      latitude: 12.9592,
      longitude: 77.6974,
    ),
    PlacePin(
      title: 'JP Nagar',
      subtitle: '6th Phase, Bengaluru',
      latitude: 12.9063,
      longitude: 77.5857,
    ),
    PlacePin(
      title: 'Hebbal',
      subtitle: 'Bellary Road, Bengaluru',
      latitude: 13.0358,
      longitude: 77.5970,
    ),
    PlacePin(
      title: 'Banashankari',
      subtitle: '3rd Stage, Bengaluru',
      latitude: 12.9255,
      longitude: 77.5468,
    ),
  ];

  static List<PlacePin> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return areas;
    return areas
        .where(
          (place) =>
              place.title.toLowerCase().contains(q) ||
              place.subtitle.toLowerCase().contains(q),
        )
        .toList();
  }

  static PlacePin nearest(double latitude, double longitude) {
    var best = areas.first;
    var bestKm = double.infinity;
    for (final place in areas) {
      final km = distanceKm(
        latitude,
        longitude,
        place.latitude,
        place.longitude,
      );
      if (km < bestKm) {
        bestKm = km;
        best = place;
      }
    }
    return best;
  }

  static ({String label, String detail}) describe(
    double latitude,
    double longitude,
  ) {
    final place = nearest(latitude, longitude);
    final km = distanceKm(latitude, longitude, place.latitude, place.longitude);
    if (km <= 2.4) {
      return (label: place.title, detail: place.subtitle);
    }
    if (km <= 8) {
      return (label: place.title, detail: 'About ${km.toStringAsFixed(1)} km from ${place.title}');
    }
    return (
      label: 'Selected pin',
      detail: 'Move the map to land on your street',
    );
  }

  static double distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthKm = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return earthKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double degrees) => degrees * pi / 180;
}
