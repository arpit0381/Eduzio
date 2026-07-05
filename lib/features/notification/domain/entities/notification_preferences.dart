class NotificationPreferences {
  final bool homework;
  final bool attendance;
  final bool fees;
  final bool results;
  final bool events;
  final bool announcements;
  final bool marketing;

  const NotificationPreferences({
    this.homework = true,
    this.attendance = true,
    this.fees = true,
    this.results = true,
    this.events = true,
    this.announcements = true,
    this.marketing = true,
  });

  NotificationPreferences copyWith({
    bool? homework,
    bool? attendance,
    bool? fees,
    bool? results,
    bool? events,
    bool? announcements,
    bool? marketing,
  }) {
    return NotificationPreferences(
      homework: homework ?? this.homework,
      attendance: attendance ?? this.attendance,
      fees: fees ?? this.fees,
      results: results ?? this.results,
      events: events ?? this.events,
      announcements: announcements ?? this.announcements,
      marketing: marketing ?? this.marketing,
    );
  }

  Map<String, bool> toMap() {
    return {
      'homework': homework,
      'attendance': attendance,
      'fees': fees,
      'results': results,
      'events': events,
      'announcements': announcements,
      'marketing': marketing,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      homework: map['homework'] as bool? ?? true,
      attendance: map['attendance'] as bool? ?? true,
      fees: map['fees'] as bool? ?? true,
      results: map['results'] as bool? ?? true,
      events: map['events'] as bool? ?? true,
      announcements: map['announcements'] as bool? ?? true,
      marketing: map['marketing'] as bool? ?? true,
    );
  }
}
