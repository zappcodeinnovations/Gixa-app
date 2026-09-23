class CollegeCategoryCutoffResponse {
  final CollegeCutoffCollege college;
  final CollegeCutoffFilters filters;
  final CollegeCutoffSummary summary;
  final List<CollegeCategoryCutoffRecord> categoryCutoffs;

  const CollegeCategoryCutoffResponse({
    required this.college,
    required this.filters,
    required this.summary,
    required this.categoryCutoffs,
  });

  factory CollegeCategoryCutoffResponse.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? const {});

    return CollegeCategoryCutoffResponse(
      college: CollegeCutoffCollege.fromJson(
        Map<String, dynamic>.from(data['college'] as Map? ?? const {}),
      ),
      filters: CollegeCutoffFilters.fromJson(
        Map<String, dynamic>.from(data['filters'] as Map? ?? const {}),
      ),
      summary: CollegeCutoffSummary.fromJson(
        Map<String, dynamic>.from(data['summary'] as Map? ?? const {}),
      ),
      categoryCutoffs: _parseCategoryCutoffs(data),
    );
  }

  static List<CollegeCategoryCutoffRecord> _parseCategoryCutoffs(Map<String, dynamic> data) {
    final List<CollegeCategoryCutoffRecord> allCutoffs = [];
    final Set<String> seen = {};

    void addCutoffs(
      List? cutoffs, {
      String? fallbackCourseName,
      dynamic fallbackSpecialityId,
      String? fallbackSpecialityName,
      String? fallbackSpecialityType,
    }) {
      if (cutoffs == null) return;
      for (final c in cutoffs) {
        if (c is Map) {
          final cMap = Map<String, dynamic>.from(c);
          if (fallbackCourseName != null &&
              (cMap['course_name'] == null ||
                  cMap['course_name'].toString().trim().isEmpty)) {
            cMap['course_name'] = fallbackCourseName;
          }
          if (fallbackSpecialityId != null && cMap['speciality_id'] == null) {
            cMap['speciality_id'] = fallbackSpecialityId;
          }
          if (fallbackSpecialityName != null &&
              (cMap['speciality_name'] == null ||
                  cMap['speciality_name'].toString().trim().isEmpty)) {
            cMap['speciality_name'] = fallbackSpecialityName;
          }
          if (fallbackSpecialityType != null &&
              (cMap['speciality_type'] == null ||
                  cMap['speciality_type'].toString().trim().isEmpty)) {
            cMap['speciality_type'] = fallbackSpecialityType;
          }

          final record = CollegeCategoryCutoffRecord.fromJson(cMap);
          final key = '${record.courseId}_${record.specialityId}_${record.quotaId}_${record.category}';
          if (!seen.contains(key)) {
            seen.add(key);
            allCutoffs.add(record);
          }
        }
      }
    }

    final coursesList = data['courses'] as List? ?? [];
    for (final courseObj in coursesList) {
      if (courseObj is Map) {
        final fallbackCourseName = courseObj['course_name']?.toString();
        addCutoffs(
          courseObj['category_cutoffs'] as List?,
          fallbackCourseName: fallbackCourseName,
        );

        final specGroups = courseObj['speciality_groups'] as List? ?? [];
        for (final groupObj in specGroups) {
          if (groupObj is Map) {
            final groupType = (groupObj['group'] ?? groupObj['group_name'])?.toString();
            final specialities = groupObj['specialities'] as List? ?? [];
            for (final specObj in specialities) {
              if (specObj is Map) {
                final specId = specObj['speciality_id'];
                final specName = specObj['speciality_name']?.toString();
                addCutoffs(
                  specObj['category_cutoffs'] as List?,
                  fallbackCourseName: fallbackCourseName,
                  fallbackSpecialityId: specId,
                  fallbackSpecialityName: specName,
                  fallbackSpecialityType: groupType,
                );
              }
            }
          }
        }
      }
    }

    if (allCutoffs.isEmpty) {
      addCutoffs(data['category_cutoffs'] as List?);
    }

    return allCutoffs;
  }
}

class CollegeCutoffCollege {
  final int id;
  final String collegeCode;
  final String collegeName;
  final String city;
  final String district;
  final String state;
  final String instituteType;

  const CollegeCutoffCollege({
    required this.id,
    required this.collegeCode,
    required this.collegeName,
    required this.city,
    required this.district,
    required this.state,
    required this.instituteType,
  });

  factory CollegeCutoffCollege.fromJson(Map<String, dynamic> json) {
    return CollegeCutoffCollege(
      id: _toInt(json['id']),
      collegeCode: json['college_code']?.toString() ?? '',
      collegeName: json['college_name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      instituteType: json['institute_type']?.toString() ?? '',
    );
  }
}

class CollegeCutoffFilters {
  final int? year;
  final int? courseId;
  final int? quotaId;
  final int? allIndiaRank;

  const CollegeCutoffFilters({
    required this.year,
    required this.courseId,
    required this.quotaId,
    required this.allIndiaRank,
  });

  factory CollegeCutoffFilters.fromJson(Map<String, dynamic> json) {
    return CollegeCutoffFilters(
      year: _toNullableInt(json['year']),
      courseId: _toNullableInt(json['course_id']),
      quotaId: _toNullableInt(json['quota_id']),
      allIndiaRank: _toNullableInt(json['all_india_rank']),
    );
  }
}

class CollegeCutoffSummary {
  final int totalCategoryRecords;
  final int eligibleCategoryRecords;

  const CollegeCutoffSummary({
    required this.totalCategoryRecords,
    required this.eligibleCategoryRecords,
  });

  factory CollegeCutoffSummary.fromJson(Map<String, dynamic> json) {
    return CollegeCutoffSummary(
      totalCategoryRecords: _toInt(json['total_category_records']),
      eligibleCategoryRecords: _toInt(json['eligible_category_records']),
    );
  }
}

class CollegeCategoryCutoffRecord {
  final int courseId;
  final String courseName;
  final int quotaId;
  final String quotaName;
  final String category;
  final String mainCategory;
  final String? allotmentCategory;
  final String? horizontalReservation;
  final int lastCutoffRank;
  final int studentRank;
  final int rankDifference;
  final bool eligible;
  final String chance;
  final int? specialityId;
  final String? specialityName;
  final String? specialityType;

  const CollegeCategoryCutoffRecord({
    required this.courseId,
    required this.courseName,
    required this.quotaId,
    required this.quotaName,
    required this.category,
    required this.mainCategory,
    required this.allotmentCategory,
    required this.horizontalReservation,
    required this.lastCutoffRank,
    required this.studentRank,
    required this.rankDifference,
    required this.eligible,
    required this.chance,
    this.specialityId,
    this.specialityName,
    this.specialityType,
  });

  factory CollegeCategoryCutoffRecord.fromJson(Map<String, dynamic> json) {
    return CollegeCategoryCutoffRecord(
      courseId: _toInt(json['course_id']),
      courseName: json['course_name']?.toString() ?? '',
      quotaId: _toInt(json['quota_id']),
      quotaName: json['quota_name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      mainCategory: json['main_category']?.toString() ?? '',
      allotmentCategory: _toNullableString(json['allotment_category']),
      horizontalReservation: _toNullableString(json['horizontal_reservation']),
      lastCutoffRank: _toInt(json['last_cutoff_rank']),
      studentRank: _toInt(json['student_rank']),
      rankDifference: _toInt(json['rank_difference']),
      eligible: json['eligible'] == true,
      chance: json['chance']?.toString() ?? '',
      specialityId: _toNullableInt(json['speciality_id']),
      specialityName: _toNullableString(json['speciality_name']),
      specialityType: _toNullableString(json['speciality_type']),
    );
  }

  String get displayCategory {
    final parts = <String>[];
    void addPart(String? value) {
      final text = value?.trim();
      if (text == null || text.isEmpty || parts.contains(text)) return;
      parts.add(text);
    }

    addPart(mainCategory.isNotEmpty ? mainCategory : null);
    addPart(horizontalReservation);
    addPart(allotmentCategory);

    if (parts.isNotEmpty) {
      return parts.join(' / ');
    }

    return category.replaceAll('|', ' / ');
  }

  String get chartLabel {
    final extra = horizontalReservation ?? allotmentCategory;
    if (extra == null || extra.trim().isEmpty) {
      return mainCategory.isEmpty ? category : mainCategory;
    }

    return '${mainCategory.isEmpty ? category : mainCategory}\n$extra';
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

String? _toNullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') {
    return null;
  }
  return text;
}
