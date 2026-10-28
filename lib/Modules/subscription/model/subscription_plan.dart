class SubscriptionPlanResponse {
  final bool status;
  final String message;
  final List<SubscriptionPlan> data;

  SubscriptionPlanResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SubscriptionPlanResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanResponse(
      status: json['status'],
      message: json['message'],
      data: List<SubscriptionPlan>.from(
        json['data'].map((x) => SubscriptionPlan.fromJson(x)),
      ),
    );
  }
}

class SubscriptionPlan {
  final int id;
  final String planName;
  final String planCode;
  final String planType;
  final String amount;
  final int durationDays;
  final String description;
  final bool isRecommended;
  final bool isAddon;
  final List<Feature> features;

  SubscriptionPlan({
    required this.id,
    required this.planName,
    required this.planCode,
    required this.planType,
    required this.amount,
    required this.durationDays,
    required this.description,
    required this.isRecommended,
    required this.features,
    this.isAddon = false,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    return SubscriptionPlan(
      id: _asInt(json['id'] ?? json['plan_id'] ?? json['subscription_plan_id']),
      planName: _asString(json['plan_name']),
      planCode: _asString(json['plan_code']),
      planType: _asString(json['plan_type']),
      amount: _asString(json['amount']),
      durationDays: _asInt(json['duration_days']),
      description: _asString(json['description']),
      isRecommended: json['is_recommended'] == true,
      features: List<Feature>.from(
        (rawFeatures is List ? rawFeatures : const [])
            .whereType<Map>()
            .map((x) => Feature.fromJson(Map<String, dynamic>.from(x))),
      ),
      isAddon: json['is_addon'] == true,
    );
  }
  bool get bestValue => isRecommended;

  
}

class Feature {
  final int id;
  final String featureCode;
  final String featureTitle;
  final String featureDescription;
  final bool isEnabled;

  /// ✅ ADD THIS
  final int? featureLimit;

  /// (optional)
  final dynamic featureValue;

  Feature({
    required this.id,
    required this.featureCode,
    required this.featureTitle,
    required this.featureDescription,
    required this.isEnabled,
    this.featureLimit,
    this.featureValue,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      id: _asInt(json['id']),
      featureCode: json['feature_code'] ?? '',
      featureTitle: json['feature_title'] ?? '',
      featureDescription: json['feature_description'] ?? '',
      isEnabled: json['is_enabled'] ?? false,

      /// ✅ SAFE PARSE (handles int / string / null)
      featureLimit: json['feature_limit'] is int
          ? json['feature_limit']
          : int.tryParse(json['feature_limit']?.toString() ?? ''),

      featureValue: json['feature_value'],
    );

    
  }

  
}

String _asString(dynamic value) {
  if (value == null) return '';
  final normalized = value.toString().trim();
  return normalized.toLowerCase() == 'null' ? '' : normalized;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
