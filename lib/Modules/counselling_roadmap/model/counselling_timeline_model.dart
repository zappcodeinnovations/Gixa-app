import 'package:intl/intl.dart';

class CounsellingTimelineResponse {
  final bool status;
  final String stateId;
  final String stateName;
  final String type;
  final String currentRound;
  final List<CounsellingDateEvent> dates;
  final List<CounsellingTimelineStep> timeline;

  CounsellingTimelineResponse({
    required this.status,
    required this.stateId,
    required this.stateName,
    required this.type,
    required this.currentRound,
    required this.dates,
    required this.timeline,
  });

  factory CounsellingTimelineResponse.fromJson(Map<String, dynamic> json) {
    return CounsellingTimelineResponse(
      status: json['status'] == true,
      stateId: json['state_id']?.toString() ?? '',
      stateName: json['state_name']?.toString() ?? '',
      type: json['type']?.toString().toLowerCase() ?? 'ug',
      currentRound: json['current_round']?.toString() ?? 'Round 1',
      dates: (json['dates'] as List<dynamic>?)
              ?.map((e) => CounsellingDateEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => CounsellingTimelineStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CounsellingDateEvent {
  final int id;
  final String round;
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status; // 'upcoming' | 'ongoing' | 'closed'
  final String description;

  CounsellingDateEvent({
    required this.id,
    required this.round,
    required this.title,
    this.startDate,
    this.endDate,
    required this.status,
    required this.description,
  });

  factory CounsellingDateEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return CounsellingDateEvent(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      round: json['round']?.toString() ?? 'Round 1',
      title: json['title']?.toString() ?? '',
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      status: (json['status']?.toString() ?? 'upcoming').toLowerCase(),
      description: json['description']?.toString() ?? '',
    );
  }

  String get formattedDateRange {
    if (startDate == null && endDate == null) return "Dates to be announced";
    final formatter = DateFormat('dd MMM yyyy, hh:mm a');
    final dateOnlyFormatter = DateFormat('dd MMM yyyy');

    if (startDate != null && endDate != null) {
      if (startDate!.day == endDate!.day &&
          startDate!.month == endDate!.month &&
          startDate!.year == endDate!.year) {
        return "${dateOnlyFormatter.format(startDate!)}, ${DateFormat('hh:mm a').format(startDate!)} - ${DateFormat('hh:mm a').format(endDate!)}";
      }
      return "${formatter.format(startDate!)}  ➔  ${formatter.format(endDate!)}";
    }

    if (startDate != null) return "Starts: ${formatter.format(startDate!)}";
    return "Ends: ${formatter.format(endDate!)}";
  }

  bool get isOngoing => status == 'ongoing' || status == 'active';
  bool get isUpcoming => status == 'upcoming';
  bool get isClosed => status == 'closed' || status == 'completed';
}

class CounsellingTimelineStep {
  final int stepNumber;
  final String round;
  final String title;
  final String description;
  final String status; // 'completed' | 'active' | 'upcoming'
  final List<String> guidelines;

  CounsellingTimelineStep({
    required this.stepNumber,
    required this.round,
    required this.title,
    required this.description,
    required this.status,
    required this.guidelines,
  });

  factory CounsellingTimelineStep.fromJson(Map<String, dynamic> json) {
    return CounsellingTimelineStep(
      stepNumber: json['step_number'] is int
          ? json['step_number'] as int
          : int.tryParse(json['step_number']?.toString() ?? '1') ?? 1,
      round: json['round']?.toString() ?? 'Round 1',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'upcoming').toLowerCase(),
      guidelines: (json['guidelines'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          [],
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isActive => status == 'active' || status == 'current' || status == 'ongoing';
  bool get isUpcoming => status == 'upcoming';
}

