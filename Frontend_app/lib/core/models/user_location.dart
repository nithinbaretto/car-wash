class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.detail = '',
    this.fromGps = false,
  });

  final double latitude;
  final double longitude;
  final String label;
  final String detail;
  final bool fromGps;

  String get headerLabel => label.startsWith('Near ') ? label : 'Near $label';
}
