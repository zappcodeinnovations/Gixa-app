import 'package:Gixa/Modules/subscription/model/create_order_model.dart';
import 'package:Gixa/Modules/subscription/model/subscription_history_model.dart';
import 'package:Gixa/Modules/subscription/model/subscription_state_model.dart';
import 'package:Gixa/network/api_client.dart';
import 'package:Gixa/network/api_endpoints.dart';
import 'package:Gixa/Modules/subscription/model/subscription_plan.dart';
import 'package:Gixa/Modules/subscription/model/subscription_purchase_model.dart';
import 'package:Gixa/Modules/subscription/model/verify_payment_response.dart';
import 'package:Gixa/Modules/subscription/model/subscription_specialty_model.dart';
import 'package:Gixa/network/app_exception.dart';

class SubscriptionApi {
  /// 🔹 GET SUBSCRIPTION PLANS
  static Future<List<SubscriptionPlan>> getPlans({
    bool forceRefresh = false,
  }) async {
    final response = await ApiClient.get(
      ApiEndpoints.subscriptionPlans,
      requestPolicy: RequestPolicy(
        ttl: Duration(minutes: 5),
        forceRefresh: forceRefresh,
      ),
    );
    print("[API] getPlans response: $response");
    final parsed = SubscriptionPlanResponse.fromJson(response);
    return parsed.data;
  }

  /// 🔹 APPLY COUPON / PRICE PREVIEW
  static Future<SubscriptionPurchaseResponse> purchaseSubscription({
    required int planId,
    String? couponCode,
    List<int>? stateIds,
    List<int>? courseIds,
  }) async {
    try {
      final response = await ApiClient.post(ApiEndpoints.subscriptionPurchase, {
        "plan_id": planId,
        if (couponCode != null && couponCode.isNotEmpty)
          "coupon_code": couponCode,
        if (stateIds != null && stateIds.isNotEmpty) "state_ids": stateIds,
        if (courseIds != null && courseIds.isNotEmpty) "course_ids": courseIds,
      });

      print("[API] purchaseSubscription response: $response");

      return SubscriptionPurchaseResponse.fromJson(response);
    } on AppException catch (e) {
      print("PURCHASE SUBSCRIPTION AppException => ${e.message}");

      return SubscriptionPurchaseResponse(
        status: false,
        message: e.message,
        data: null,
      );
    } catch (e) {
      print("PURCHASE SUBSCRIPTION ERROR => $e");

      return SubscriptionPurchaseResponse(
        status: false,
        message: 'Something went wrong',
        data: null,
      );
    }
  }

  /// 🔥 CREATE ORDER (REAL PAYMENT)
  static Future<CreateOrderResponse> createOrder({
    required int planId,
    required int baseAmount,
    required int finalAmount,
    String? couponCode,
    int extraDays = 0,
    List<int>? stateIds,
    List<int>? courseIds,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoints.subscriptionCreateOrder,
      {
        "plan_id": planId,
        "base_amount": baseAmount.toString(),
        "final_amount": finalAmount.toString(),
        "coupon_code": couponCode ?? "",
        "extra_days": extraDays,
        if (stateIds != null && stateIds.isNotEmpty) "state_ids": stateIds,
        if (courseIds != null && courseIds.isNotEmpty) "course_ids": courseIds,
      },
    );
    print("[API] createOrder response: $response");
    return CreateOrderResponse.fromJson(response);
  }

  /// ✅ VERIFY PAYMENT
  static Future<VerifyPaymentResponse> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final response =
        await ApiClient.post(ApiEndpoints.subscriptionVerifyPayment, {
          "razorpay_order_id": razorpayOrderId,
          "razorpay_payment_id": razorpayPaymentId,
          "razorpay_signature": razorpaySignature,
        });
    print("[API] verifyPayment response: $response");
    return VerifyPaymentResponse.fromJson(response);
  }

  /// 🧾 GET SUBSCRIPTION HISTORY
  static Future<List<SubscriptionHistory>> getSubscriptionHistory({
    required int userId,
    bool forceRefresh = false,
  }) async {
    final response = await ApiClient.get(
      ApiEndpoints.subscriptionHistory(userId),
      requestPolicy: RequestPolicy(
        ttl: Duration(seconds: 30),
        forceRefresh: forceRefresh,
      ),
    );

    print("[API] getSubscriptionHistory response: $response");

    if (response is! Map<String, dynamic>) {
      throw Exception("Invalid response format");
    }

    final data = response['data'];

    if (data is! List) {
      throw Exception("Invalid subscription list");
    }

    return data
        .map((e) => SubscriptionHistory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<SubscriptionStateData> getStatesWithoutSubscription() async {
    final response = await ApiClient.get(ApiEndpoints.subscriptionStates);

    print("🔥 STATES API RESPONSE: $response");

    final parsed = SubscriptionStateResponse.fromJson(response);
    return parsed.data;
  }

  static Future<dynamic> saveSubscriptionStates({
    required int subscriptionId,
    required List<int> stateIds,
    List<int>? courseIds,
  }) async {
    final response = await ApiClient.post(ApiEndpoints.subscriptionStates, {
      "subscription_id": subscriptionId,
      "state_ids": stateIds,
      if (courseIds != null && courseIds.isNotEmpty) "course_ids": courseIds,
    });

    if (response['status'] != true) {
      throw Exception(response['message'] ?? "Failed to save states");
    }
  }

  /// 🔹 GET SUBSCRIPTION SPECIALTIES
  static Future<SubscriptionSpecialtyData?> getSubscriptionSpecialties({
    bool forceRefresh = false,
  }) async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.subscriptionSpecialties,
        requestPolicy: RequestPolicy(
          ttl: const Duration(minutes: 5),
          forceRefresh: forceRefresh,
        ),
      );
      print("🔥 SPECIALTIES API RESPONSE: $response");
      final parsed = SubscriptionSpecialtyResponse.fromJson(response);
      return parsed.data;
    } catch (e) {
      print("GET SPECIALTIES ERROR => $e");
      return null;
    }
  }
}
