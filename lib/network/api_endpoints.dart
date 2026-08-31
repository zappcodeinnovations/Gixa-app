class ApiEndpoints {
  ApiEndpoints._();

  /// AUTH – OTP
  static const String sendOtp = '/api/student/send-otp/';
  static const String verifyOtp = '/api/student/verify-otp/';
  static const String logout = '/api/logout/';
  static const logoutOtherDevice = '/api/logout-other-device/';

  /// AUTH – TOKEN
  static const String refreshToken = '/api/student/refresh-token/';

  /// AUTH – GOOGLE
  static const String googleLogin = '/auth/google';

  static const removeProfileImage = "/api/student/profile/remove-image/";

  /// Payment
  static const String paymentCredentials = '/api/payment-credentials/';

  //ragisterss
  static const String registerStudent = '/api/student/register/';
  //masters
  static const masters = '/api/masters/';

  static const String profile = '/api/student/profile/';

  /// 🏫 COLLEGES
  static const String colleges = '/api/colleges';
  static const String college = '/api/college';

  //fav collage
  static const String addToFavourite = '/api/student/favourite-colleges/';
  static const String removeFromFavourite =
      '/api/student/favourite-colleges/remove/';
  static const String favourite = '/api/student/favourite-colleges/';
  //seat matrix
  static const String seatMatrix = "/api/seat-matrix/";

  // Compare Collage
  static const String compareColleges = '/api/colleges/compare/';
  static const String saveCompareColleges = '/api/colleges/compare/save/';
  static const String compareHistory = '/api/colleges/compare/history/';
  static const String deleteCompareHistory = '/api/colleges/compare/delete/';

  //prediction
  static const String predictCollege = "/api/prediction/";

  /// 💳 SUBSCRIPTIONS
  static const String subscriptionPlans = '/subscription-plans/';
  static const String subscriptionPurchase = '/api/subscription/purchase/';
  static const String subscriptionCreateOrder =
      '/api/student/subscription/create-order/';
  static const String subscriptionVerifyPayment =
      '/api/student/subscription/verify-payment/';
  static String subscriptionHistory(int userId) =>
      "/api/subscriptions/user/$userId/";
  //Documents
  static const String documents = '/api/student/documents/upload/';
  static const updateStudentDocument = '/api/student/documents/update/';
  static const String studentDocuments = "/api/student/documents/";
  static const String predictionSheets = "/api/student/prediction-sheets/";

  /// 💬 CHAT SUPPORT (BOT + HUMAN)
  static const String chatStart = '/api/chat/start/';
  static const String chatBotResponse = '/api/chat/bot-response/';
  static const String chatSwitchToHuman = '/api/chat/switch-to-human/';
  static const String chatAdmission = '/api/chat/admission/';
  static const String chatMessage = '/api/chat/message/';
  static const String chatClear = '/api/chat/clear/';
  static const String chatClose = '/api/chat/close/';
  static String chatMessages({
    required String sessionId,
    String? lastMessageId,
  }) {
    return '/api/chat/messages/?session_id=$sessionId'
        '${lastMessageId != null ? '&last_message_id=$lastMessageId' : ''}';
  }

  static String chatHistory(String sessionId) => '/api/chat/history/?session_id=$sessionId';
  static String chatSessions(String entryFlow) => '/api/chat/sessions/?entry_flow=$entryFlow';

  /// 🎓 ASSISTANCE – COUNSELORS
  static const String assistanceCounselors = '/api/assistance/counselors/';
  static const String selectCounselor = '/api/assistance/select-counselor/';
  static const String counselorDetail = '/api/assistance/counselor';
  static const String requestGuidance = "/api/request-guidance/";
  static String requestGuidanceDetail(int requestId) =>
      "/api/request-guidance/$requestId/";
  //notification
  static const String studentNotifications = '/api/student/notifications/';
  static String markNotificationRead(int id) => '/api/notifications/$id/mark-read/';
  static const String markAllNotificationsRead = '/api/notifications/mark-all-read/';
  static String deleteNotification(int id) => '/api/notifications/$id/delete/';
  static const String deleteAllNotifications = '/api/notifications/delete-all/';
  static const String deleteReadNotifications = '/api/notifications/delete-read/';
  static const String notificationSettings = '/api/user/notification-settings/';
  static const String putNotifcationSettings =
      '/api/user/notification-settings/';
  static const String supportContact = "/api/support/contact/";
  //version check
  static const String versionCheck = "/app/version-check/";
  static const String createTicket = "/api/tickets/create/";
  static const String getTickets = "/api/tickets/";
  static const String ticketReply = "/api/tickets/reply/";
  static const String availableCategories =
      "/api/prediction/available-categories/";
  static const String rankAnalysis = "/api/rank-analysis/college/";
  static const String faq = "/api/faqs/";
  static const String appAlerts = "/api/app-alerts/";
  static const String termsConditions = "/api/terms-conditions/";
  static const String addonContact = "/api/get_addon_contact/";
  static const airComparison = "/api/air-comparison/";
  static const String statewiseAvailability =
      "/api/prediction/statewise-availability/";
  static const String subscriptionStates = '/api/student/subscription/states/';
  static const String appVerification = '/api/app-verification/';
  static String neetRankPredictor(int score) {
    return "/api/neet-rank-predictor/?score=$score";
  }

  // 🔔 ALERTS / NEWS FEED
  static const String alerts = '/alert/api/notifications/';

  // State-wise rank distribution
  static const String stateWiseRankDistribution = '/api/state-wise-rank-distribution/';
}
