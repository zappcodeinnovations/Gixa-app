import 'package:Gixa/Modules/Profile/models/document_model.dart';
import 'package:Gixa/Modules/register/model/register_response.dart';

class ProfileModel {
  final int id;
  final User user;

  final int? allIndiaRank;
  final bool? allIndiaRankUpdatedOnce;
  final int? neetScore;

  final String? tenthPercentage;
  final String? twelthPercentage;
  final String? twelthPcb;

  final String? category;
  final int? categoryId;
  final String? state;
  final int? stateId;
  final String? course;
  final int? courseId;
  final String? specialty;
  final String? gender;
  final String? quota;
  final String? instituteType;
  final List<String>? horizontals;
  final String? caste;
  final String? nationality;
  final String? dateOfBirth;
  final String? address;

  final bool isProfileCompleted;
  final bool isVerified;

  final List<Document> documents;
  final String? profilePictureUrl;
  final String? disabilityDetails;
  final bool? physicalDisability;
  final List<String>? predictionCourses;
  final String? courseLevel;

  ProfileModel({
    required this.id,
    required this.user,
    this.predictionCourses,
    this.allIndiaRank,
    this.allIndiaRankUpdatedOnce,
    this.neetScore,
    this.tenthPercentage,
    this.twelthPercentage,
    this.twelthPcb,
    this.category,
    this.categoryId,
    this.state,
    this.stateId,
    this.course,
    this.courseId,
    this.specialty,
    this.gender,
    this.quota,
    this.instituteType,
    this.horizontals,
    this.caste,
    this.nationality,
    this.dateOfBirth,
    this.address,
    this.profilePictureUrl,
    required this.isProfileCompleted,
    required this.isVerified,
    required this.documents,
    this.disabilityDetails,
    this.physicalDisability,
    this.courseLevel,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : Map<String, dynamic>.from(
            (json['user'] as Map?) ?? <String, dynamic>{},
          );

    final profilePictureUrl =
        userJson['profile_picture_url']?.toString() ??
        userJson['profile_picture']?.toString() ??
        json['profile_picture_url']?.toString() ??
        json['profile_picture']?.toString();

    final categoryValue = json['category'];
    final stateValue = json['state'];
    final courseValue = json['course'];

    return ProfileModel(
      id: _toInt(json['id']) ?? 0,
      user: User.fromJson(userJson),
      allIndiaRank: _toInt(json['all_india_rank']),
      allIndiaRankUpdatedOnce: json['all_india_rank_updated_once'] == true,
      neetScore: _toInt(json['neet_score']),
      tenthPercentage: json['tenth_percentage']?.toString(),
      twelthPercentage: json['twelth_percentage']?.toString(),
      twelthPcb: json['twelth_pcb']?.toString(),
      category: _readLabel(
        categoryValue,
        preferredKeys: const ['category_name', 'name', 'label'],
      ),
      categoryId: _readId(categoryValue),
      state: _readLabel(
        stateValue,
        preferredKeys: const ['state_name', 'name', 'label'],
      ),
      stateId: _readId(stateValue),
      course: _readLabel(
        courseValue,
        preferredKeys: const ['course_name', 'name', 'label'],
      ),
      courseId: _readId(courseValue),
      specialty: json['specialty']?.toString(),
      gender: json['gender']?.toString(),
      quota: json['quota']?.toString(),
      instituteType:
          json['institute_type']?.toString() ??
          json['instituteType']?.toString(),
      horizontals: json['disability_details'] != null
          ? json['disability_details']
                .toString()
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : [],
      caste: json['caste']?.toString(),
      nationality: json['nationality']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      address: json['address']?.toString(),
      isProfileCompleted: json['is_profile_completed'] == true,
      isVerified: json['is_verified'] == true,
      documents: (json['documents'] as List<dynamic>? ?? [])
          .map((e) => Document.fromJson(e))
          .toList(),
      profilePictureUrl: profilePictureUrl,
      disabilityDetails: json['disability_details']?.toString(),
      physicalDisability: json['physical_disability'] == true,
      predictionCourses: (json['prediction_courses'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      courseLevel: json['course_level']?.toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static int? _readId(dynamic value) {
    if (value is Map<String, dynamic>) {
      return _toInt(value['id'] ?? value['pk'] ?? value['value']);
    }

    return _toInt(value);
  }

  static String? _readLabel(
    dynamic value, {
    List<String> preferredKeys = const [],
  }) {
    if (value == null) return null;

    if (value is Map<String, dynamic>) {
      for (final key in preferredKeys) {
        final candidate = value[key]?.toString().trim();
        if (candidate != null && candidate.isNotEmpty) {
          return candidate;
        }
      }

      final fallbackKeys = const ['title', 'display_name', 'value'];
      for (final key in fallbackKeys) {
        final candidate = value[key]?.toString().trim();
        if (candidate != null && candidate.isNotEmpty) {
          return candidate;
        }
      }

      return _readId(value)?.toString();
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
