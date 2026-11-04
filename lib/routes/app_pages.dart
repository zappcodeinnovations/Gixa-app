import 'package:Gixa/Modules/Auth/controllers/otp_controller.dart';
import 'package:Gixa/Modules/Chatbot/view/chatbot_view.dart';
import 'package:Gixa/Modules/Chatbot/view/admission_chat_view.dart';
import 'package:Gixa/Modules/Collage/veiw/collage_list_page.dart';
import 'package:Gixa/Modules/CollageDetails/view/collage_details_page.dart';
import 'package:Gixa/Modules/Documents/view/documents_view.dart';
import 'package:Gixa/Modules/Documents/view/update_doc_page.dart';
import 'package:Gixa/Modules/Documents/view/view_documents_page.dart';
import 'package:Gixa/Modules/Home/Veiw/home_page.dart';
import 'package:Gixa/Modules/Profile/views/profile_screen.dart';
import 'package:Gixa/Modules/comparison/controller/college_compare_controller.dart';
import 'package:Gixa/Modules/comparison/view/compare_colleges_page.dart';
import 'package:Gixa/Modules/comparison/view/compare_history_save.dart';
import 'package:Gixa/Modules/favourite/view/favourite_colleges_page.dart';
import 'package:Gixa/Modules/predication/view/predication_view.dart';
import 'package:Gixa/Modules/counselling_roadmap/view/counselling_roadmap_screen.dart';
import 'package:Gixa/Modules/counselling_roadmap/view/counselling_timeline_page.dart';
import 'package:Gixa/Modules/register/view/register_page.dart';
import 'package:Gixa/Modules/settings/view/about_page.dart';
import 'package:Gixa/Modules/settings/view/data_storage_page.dart';
import 'package:Gixa/Modules/settings/view/feedback_page.dart';
import 'package:Gixa/Modules/settings/view/langauge_page.dart';
import 'package:Gixa/Modules/settings/view/notification_settings_page.dart';
import 'package:Gixa/Modules/splash/splash_screen.dart';
import 'package:Gixa/Modules/subscription/view/my_packages_page.dart';
import 'package:Gixa/Modules/subscription/view/subscription_plan_page.dart';
import 'package:Gixa/Modules/support/view/support_page.dart';
import 'package:Gixa/Modules/ticket/view/ticket_view.dart';
import 'package:Gixa/Modules/updateProfile/view/edit_profile_screen.dart';
import 'package:Gixa/Modules/notification/veiw/alerts_page.dart';
import 'package:Gixa/bindings/admission_chat_binding.dart';
import 'package:Gixa/bindings/chat_binding.dart';
import 'package:Gixa/bindings/college_compare_binding.dart';
import 'package:Gixa/bindings/document_upload_binding.dart';
import 'package:Gixa/bindings/home_binding.dart';
import 'package:Gixa/bindings/predication_binding.dart';
import 'package:Gixa/bindings/profile_binding.dart';
import 'package:Gixa/bindings/subscription_binding.dart';
import 'package:Gixa/bindings/update_profile_binding.dart';
import 'package:Gixa/naivgation/controller/nav_bar_controller.dart';
import 'package:get/get.dart';
import 'package:Gixa/Modules/onbording/view/onboarding_screen.dart';
import 'package:Gixa/Modules/Auth/Veiw/login_with_otp_page.dart';
import 'package:Gixa/Modules/Auth/Veiw/verify_otp_page.dart';
import 'package:Gixa/Modules/Search/veiw/search_page.dart';
import 'package:Gixa/Modules/notification/veiw/notification_page.dart';
import 'package:Gixa/naivgation/veiw/main_nav_page.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final routes = <GetPage>[
    /// SPLASH
    GetPage(name: AppRoutes.splash, page: () => SplashScreen()),

    /// ONBOARDING
    GetPage(name: AppRoutes.onboarding, page: () => OnboardingView()),

    /// AUTH
    GetPage(
      name: AppRoutes.loginWithOtp,
      page: () => LoginWithOtpPage(),
      binding: BindingsBuilder(() {
        Get.put(OtpController());
      }),
    ),
    GetPage(
      name: AppRoutes.verifyOtp,
      page: () => VerifyOtpPage(),
      binding: BindingsBuilder(() {
        Get.put(OtpController());
      }),
    ),

    /// REGISTER
    GetPage(name: AppRoutes.register, page: () => RegisterPage()),

    /// PROFILE
    // GetPage(name: AppRoutes.completeProfile, page: () => ProfilePage()),
    GetPage(
      name: AppRoutes.profile,
      page: () => ProfilePage(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => EditProfileView(),
      binding: UpdateProfileBinding(),
    ),

    /// NOTIFICATIONS
    GetPage(name: AppRoutes.notifications, page: () => NotificationPage()),
    GetPage(name: AppRoutes.alerts, page: () => AlertsPage()),

    /// SEARCH
    GetPage(name: AppRoutes.search, page: () => CollegeSearchPage()),

    /// NAVBAR (MAIN APP)
    GetPage(
      name: AppRoutes.mainNav,
      page: () => MainNavPage(),
      binding: BindingsBuilder(() {
        Get.put(MainNavController());
        Get.put(CollegeCompareController(), permanent: true);
      }),
    ),

    /// SUBSCRIPTION
    GetPage(
      name: AppRoutes.subscription,
      page: () => SubscriptionPage(),
      binding: SubscriptionBinding(),
    ),

    GetPage(
      name: AppRoutes.fevouriteCollage,
      page: () => FavouriteCollegesPage(),
    ),

    /// HOME
    GetPage(
      name: AppRoutes.home,
      page: () => HomePage(),
      binding: HomeBinding(),
    ),

    /// COLLEGE LIST
    GetPage(
      name: AppRoutes.collage,
      page: () => CollegeListPage(),
      binding: CollegeCompareBinding(),
    ),

    /// COLLEGE DETAILS
    GetPage(name: AppRoutes.collageDetails, page: () => CollegeDetailPage()),
    GetPage(
      name: AppRoutes.compareCollage,
      page: () => const CompareCollegesView(),
      binding: CollegeCompareBinding(),
    ),
    GetPage(name: AppRoutes.savedComparision, page: () => CompareHistoryView()),

    GetPage(
      name: AppRoutes.viewDocuments,
      page: () => DocumentsGalleryPage(),
      binding: DocumentBinding(),
    ),

    GetPage(
      name: AppRoutes.documents,
      page: () => UploadDocumentPage(),
      binding: DocumentBinding(), // ✅ IMPORTANT
    ),

    GetPage(
      name: AppRoutes.updateDocs,
      page: () => StudentDocumentsUnifiedPage(),
      binding: DocumentBinding(),
    ),

    // chatBot
    GetPage(
      name: AppRoutes.chatBot,
      page: () => ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: AppRoutes.admissionChat,
      page: () => AdmissionChatView(),
      binding: AdmissionChatBinding(),
    ),
    GetPage(name: AppRoutes.settings, page: () => LangaugePage()),
    GetPage(
      name: AppRoutes.notificationSettings,
      page: () => NotificationSettingsScreen(),
    ),
    GetPage(name: AppRoutes.support, page: () => SupportPage()),
    GetPage(name: AppRoutes.myPackage, page: () => MyPackagesPage()),
    GetPage(name: AppRoutes.about, page: () => AboutPage()),
    GetPage(name: AppRoutes.feedback, page: () => FeedbackPage()),
    GetPage(name: AppRoutes.data_storage, page: () => DataStoragePage()),
    GetPage(
      name: AppRoutes.prediction,
      page: () => PredictionView(),
      binding: PredicationBinding(),
    ),
    GetPage(
      name: AppRoutes.choiceFilling,
      page: () => CounsellingRoadmapScreen(),
    ),
    GetPage(name: AppRoutes.ticket, page: () => CreateTicketView()),
    GetPage(
      name: AppRoutes.counsellingTimeline,
      page: () => const CounsellingTimelinePage(initialTabIndex: 0),
    ),
    GetPage(
      name: AppRoutes.importantDates,
      page: () => const CounsellingTimelinePage(initialTabIndex: 1),
    ),
  ];
}
