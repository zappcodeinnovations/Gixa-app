class SubscriptionSpecialtyResponse {
  final bool status;
  final String? message;
  final SubscriptionSpecialtyData? data;

  SubscriptionSpecialtyResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory SubscriptionSpecialtyResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionSpecialtyResponse(
      status: json['status'] == true,
      message: json['message']?.toString(),
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? SubscriptionSpecialtyData.fromJson(json['data'])
          : null,
    );
  }
}

class SubscriptionSpecialtyData {
  final List<SpecialtyAddonCourse> courses;

  SubscriptionSpecialtyData({required this.courses});

  factory SubscriptionSpecialtyData.fromJson(Map<String, dynamic> json) {
    final rawCourses = json['courses'] as List? ?? [];
    return SubscriptionSpecialtyData(
      courses: rawCourses
          .whereType<Map<String, dynamic>>()
          .map((c) => SpecialtyAddonCourse.fromJson(c))
          .toList(),
    );
  }
}

class SpecialtyAddonCourse {
  final int courseId;
  final String courseName;
  final List<SpecialtyAddonItem> specialties;

  SpecialtyAddonCourse({
    required this.courseId,
    required this.courseName,
    required this.specialties,
  });

  factory SpecialtyAddonCourse.fromJson(Map<String, dynamic> json) {
    final rawSpecs = json['specialties'] as List? ?? [];
    return SpecialtyAddonCourse(
      courseId: _toInt(json['course_id']),
      courseName: json['course_name']?.toString() ?? '',
      specialties: rawSpecs
          .whereType<Map<String, dynamic>>()
          .map((s) => SpecialtyAddonItem.fromJson(s))
          .toList(),
    );
  }

  static int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? -1;
    return -1;
  }
}

class SpecialtyAddonItem {
  final int id;
  final String specialtyName;
  final String amount;

  SpecialtyAddonItem({
    required this.id,
    required this.specialtyName,
    required this.amount,
  });

  factory SpecialtyAddonItem.fromJson(Map<String, dynamic> json) {
    return SpecialtyAddonItem(
      id: _toInt(json['id']),
      specialtyName: json['specialty_name']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0.00',
    );
  }

  double get amountAsDouble {
    return double.tryParse(amount) ?? 0.0;
  }

  static int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? -1;
    return -1;
  }
}
