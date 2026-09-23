class SubscriptionStateResponse {
  final bool status;
  final String message;
  final SubscriptionStateData data;

  SubscriptionStateResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SubscriptionStateResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionStateResponse(
      status: json['status'] ?? false,
      message: json['message']?.toString() ?? '',
      data: SubscriptionStateData.fromJson(json['data'] ?? {}),
    );
  }
}

class SubscriptionStateData {
  final int subscriptionId;
  final int planId;
  final String planName;
  final int? allowedStateCount;
  final int selectedStateCount;
  final List<StateItem> availableStates;
  final List<StateItem> selectedStates;
  final List<AvailableCourse> availableCourses;
  final List<AvailableCourse> selectedCourses;
  final double courseTotalAmount;

  SubscriptionStateData({
    required this.subscriptionId,
    required this.planId,
    required this.planName,
    required this.allowedStateCount,
    required this.selectedStateCount,
    required this.availableStates,
    required this.selectedStates,
    required this.availableCourses,
    required this.selectedCourses,
    required this.courseTotalAmount,
  });

  factory SubscriptionStateData.fromJson(Map<String, dynamic> json) {
    return SubscriptionStateData(
      subscriptionId:
          int.tryParse(json['subscription_id']?.toString() ?? '') ?? 0,
      planId: int.tryParse(json['plan_id']?.toString() ?? '') ?? 0,
      planName: json['plan_name']?.toString() ?? "",
      allowedStateCount: json['allowed_state_count'] != null
          ? int.tryParse(json['allowed_state_count'].toString())
          : null,
      selectedStateCount:
          int.tryParse(json['selected_state_count']?.toString() ?? '') ?? 0,
      availableStates: (json['available_states'] as List?)
              ?.map((e) => StateItem.fromJson(e ?? {}))
              .toList() ??
          [],
      selectedStates: (json['selected_states'] as List?)
              ?.map((e) => StateItem.fromJson(e ?? {}))
              .toList() ??
          [],
      availableCourses: (json['available_courses'] as List?)
              ?.map((e) => AvailableCourse.fromJson(e ?? {}))
              .toList() ??
          [],
      selectedCourses: (json['selected_courses'] as List?)
              ?.map((e) => AvailableCourse.fromJson(e ?? {}))
              .toList() ??
          [],
      courseTotalAmount:
          double.tryParse(json['course_total_amount']?.toString() ?? '0') ??
          0.0,
    );
  }
}

class StateItem {
  final int id;
  final String name;
  final String? fullForm;

  StateItem({
    required this.id,
    required this.name,
    this.fullForm,
  });

  factory StateItem.fromJson(Map<String, dynamic> json) {
    return StateItem(
      id: int.tryParse(
              (json['id'] ?? json['state_id'])?.toString() ?? '') ??
          -1,
      name: (json['name'] ?? json['state_name'])?.toString() ?? "Unknown",
      fullForm: (json['full_form'] ?? json['full_name'])?.toString(),
    );
  }
}

class AvailableCourse {
  final int courseId;
  final int id;
  final String courseName;
  final String courseCode;
  final double amount;

  AvailableCourse({
    required this.courseId,
    required this.id,
    required this.courseName,
    required this.courseCode,
    required this.amount,
  });

  factory AvailableCourse.fromJson(Map<String, dynamic> json) {
    final parsedId = int.tryParse(json['id']?.toString() ?? '') ?? -1;
    final parsedCourseId =
        int.tryParse(json['course_id']?.toString() ?? '') ?? -1;
    final effectiveId = parsedId != -1 ? parsedId : parsedCourseId;
    final effectiveCourseId = parsedCourseId != -1 ? parsedCourseId : parsedId;

    return AvailableCourse(
      courseId: effectiveCourseId,
      id: effectiveId,
      courseName: (json['course_name'] ?? json['name'] ?? json['title'])
              ?.toString() ??
          "Unknown",
      courseCode: (json['course_code'] ?? json['code'])?.toString() ?? "Unknown",
      amount: double.tryParse(
              (json['amount'] ?? json['price'] ?? json['fee'])?.toString() ??
                  '0') ??
          0.0,
    );
  }
}