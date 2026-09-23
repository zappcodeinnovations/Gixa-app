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
    final status = json['status'] ?? json['success'] ?? true;
    final dynamic rawData = json['data'];
    final Map<String, dynamic> dataMap = (rawData is Map<String, dynamic>)
        ? rawData
        : (rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : json);

    return CreateOrderResponse(
      status: status is bool ? status : (status.toString().toLowerCase() == 'true'),
      message: json['message']?.toString() ?? '',
      data: CreateOrderData.fromJson(dataMap),
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
