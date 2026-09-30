/// Converts a weekly opening window into independently bookable slots.
/// Times belong to the shop's timezone (Asia/Kolkata), not the device timezone.
List<Map<String, dynamic>> buildOnboardingAvailability({
  required DateTime firstDate,
  required int days,
  required String opensAt,
  required String closesAt,
  required int slotMinutes,
  required int capacity,
}) {
  int minutes(String time) {
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(time)) {
      throw const FormatException('Use HH:mm for opening and closing times.');
    }
    final parts = time.split(':').map(int.parse).toList();
    if (parts[0] > 23 || parts[1] > 59) {
      throw const FormatException(
        'Enter a valid time between 00:00 and 23:59.',
      );
    }
    return parts[0] * 60 + parts[1];
  }

  final start = minutes(opensAt);
  final end = minutes(closesAt);
  if (days < 1 ||
      days > 31 ||
      capacity < 1 ||
      capacity > 100 ||
      slotMinutes < 1) {
    throw const FormatException(
      'Choose 1–31 days and 1–100 simultaneous bookings.',
    );
  }
  if (end - start < slotMinutes) {
    throw const FormatException(
      'The opening window must fit your longest service.',
    );
  }
  if ((end - start) ~/ slotMinutes > 100) {
    throw const FormatException(
      'Use a shorter opening window: at most 100 slots per day.',
    );
  }
  String time(int value) =>
      '${(value ~/ 60).toString().padLeft(2, '0')}:${(value % 60).toString().padLeft(2, '0')}';
  return List.generate(days, (offset) {
    final day = DateTime(
      firstDate.year,
      firstDate.month,
      firstDate.day + offset,
    );
    return {
      'date': day.toIso8601String().split('T').first,
      'slots': [
        for (
          var cursor = start;
          cursor + slotMinutes <= end;
          cursor += slotMinutes
        )
          {
            'startAt': time(cursor),
            'endAt': time(cursor + slotMinutes),
            'capacity': capacity,
            'enabled': true,
          },
      ],
    };
  });
}
