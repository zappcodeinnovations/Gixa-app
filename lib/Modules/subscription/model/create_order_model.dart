class CreateOrderResponse {
  final bool status;
  final String message;
  final CreateOrderData data;

  CreateOrderResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: CreateOrderData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
    );
  }
}

class CreateOrderData {
  final int subscriptionId;
  final String razorpayOrderId;
  final String finalAmount;

  CreateOrderData({
    required this.subscriptionId,
    required this.razorpayOrderId,
    required this.finalAmount,
  });

  factory CreateOrderData.fromJson(Map<String, dynamic> json) {
    return CreateOrderData(
      subscriptionId: json['subscription_id'] ?? json['id'] ?? 0,
      razorpayOrderId: json['razorpay_order_id'] ?? json['order_id'] ?? '',
      finalAmount: json['final_amount']?.toString() ?? json['amount']?.toString() ?? '0',
    );
  }
}
